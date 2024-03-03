package utils

import (
	"context"
	"fmt"
	"github.com/redis/go-redis/v9"
	"log"
	"strconv"
	"strings"
	"time"
)

type ErrorNoRecord struct {
}

func (e *ErrorNoRecord) Error() string {
	return "No records for the branch"
}

var redisAddr = "192.168.2.89:6379"

func ConnectRedis() (*redis.Client, context.Context) {
	rdb := redis.NewClient(
		&redis.Options{
			Addr: redisAddr,
		})
	ctx := context.Background()
	return rdb, ctx
}

func getSyncedValue(key string) bool {
	rdb, ctx := ConnectRedis()
	res := rdb.HGet(ctx, key, "Synced")
	sync, err := res.Result()
	if err != nil {
		log.Fatal(err)
	}
	synced, err := strconv.ParseBool(sync)
	if err != nil {
		log.Fatal(err)
	}
	return synced

}

// to be invoked by grayjob after build to create the record, or
// to be invoked by prod job to update  the synced value with true, after sync the image or html to prod
func AddOrModifyRecord(branchAndType, service string, synced bool) {
	rdb, ctx := ConnectRedis()
	key := branchAndType + ":" + service
	status := rdb.HSet(ctx, key, "Synced", synced)
	_, err := status.Result()

	if err != nil {
		panic(err)
	}
	fmt.Println("add or update record successfully:  " + key)
}

func findRecords(branchAndType string) ([]string, error) {
	rdb, ctx := ConnectRedis()
	pattern := branchAndType + ":*"
	// branchAndType, for  sample 20240220:java or  20240220:html
	res := rdb.Keys(ctx, pattern)
	return res.Result()
}

func uniqueSliceElements[T comparable](inputSlice []T) []T {
	uniqueSlice := make([]T, 0, len(inputSlice))
	seen := make(map[T]bool, len(inputSlice))
	for _, element := range inputSlice {
		if !seen[element] {
			uniqueSlice = append(uniqueSlice, element)
			seen[element] = true
		}
	}
	return uniqueSlice
}

func GetAllBranches() ([]string, error) {
	rdb, ctx := ConnectRedis()
	pattern := "20*"
	res := rdb.Keys(ctx, pattern)
	branches, err := res.Result()
	if err != nil {
		return nil, err
	}
	var branchList []string
	for _, branch := range branches {
		realBranch := strings.Split(branch, ":")[0]
		branchList = append(branchList, realBranch)

	}
	return uniqueSliceElements(branchList), nil
}

func FindBranchDetails(branch string) (map[string]bool, error) {
	rdb, ctx := ConnectRedis()
	pattern := branch + ":*"

	details := make(map[string]bool)
	// branchAndType, for  sample 20240220:java or  20240220:html
	res := rdb.Keys(ctx, pattern)
	keys, err := res.Result()
	if err != nil {
		return nil, err
	}
	if len(keys) > 0 {
		for _, key := range keys {
			value := getSyncedValue(key)
			details[key] = value
		}
	}
	return details, nil
}

func syncWithProd(branchAndType string) {
	records, err := findRecords(branchAndType)
	if err != nil {
		fmt.Println(err)
		return
	}
	if len(records) > 0 {
		for _, record := range records {
			service := strings.Split(record, ":")[2]
			jenkinsJob := "sync-prodv5-" + service
			err := JenkinsBuild(jenkinsJob)
			if err != nil {
				msg := keyword + "############################  Jenkins JOB fails to invoke: " + jenkinsJob + "  ######################  "
				NotifyAlls(msg)
				return
			}
			//invokeJenkinsJob(jenkinsJob, branchAndType, service)
		}
	} else {
		fmt.Println("there is no such service in this branch with the pattern: " + branchAndType + " so skip to syn this kind of jenkins job")
	}
	msg := "executing jenkins job for " + branchAndType + " ################"
	NotifyAlls(msg)
}

func invokeJenkinsJob(jenkinsJob, branchAndType, service string) {
	println(jenkinsJob + "started ")

	time.Sleep(4 * time.Second) // simulate the real jenkins job execution

	// branchAndType, for  sample 20240220:java or  20240220:html
	AddOrModifyRecord(branchAndType, service, true)
}

func isSynced(branchAndType string, synced chan string) {
	records, err := findRecords(branchAndType)
	if err != nil {
		panic(err)
	}
	total := len(records)

	if total > 0 {
		for {
			counter := 0
			for _, record := range records {
				service := strings.Split(record, ":")[2]
				key := branchAndType + ":" + service
				if getSyncedValue(key) {
					fmt.Println(service + "is  synced !!!!!!!!!!!!!!!!!")
					counter = counter + 1
				} else {
					fmt.Println(service + " is NOT synced .........")
				}
			}

			if total == counter {
				fmt.Println(branchAndType + " is all synced")
				synced <- "synced"
				close(synced)
				break
			}
			time.Sleep(2 * time.Second)
		}

	} else {
		synced <- "synced"
		close(synced)
		fmt.Println("there is no such service in this branch with the pattern: " + branchAndType + " so skip to syn this kind of jenkins job")

	}
}

func SyncFull(branch string) {
	javaSynced := make(chan string)
	msg := keyword + "----------------------- sync " + "java" + " ----------------------------"
	NotifyAlls(msg)
	javaPrefix := branch + ":" + "java"
	go func() {
		syncWithProd(javaPrefix)
	}()
	go isSynced(javaPrefix, javaSynced)
	// wait all java jenkins jobs complete.
	<-javaSynced

	htmlSynced := make(chan string)

	msg = keyword + branch + "----------------------- sync " + "html" + " ----------------------------"
	NotifyAlls(msg)

	htmlPrefix := branch + ":" + "html"
	go func() {
		syncWithProd(htmlPrefix)
	}()
	go isSynced(htmlPrefix, htmlSynced)
	<-htmlSynced
	// wait all html jenkins jobs to  complete.

	msg = keyword + branch + "  has been all synced!!!!"
	NotifyAlls(msg)
}

func NotifyAlls(msg string) {
	msg = keyword + msg
	log.Println(msg)
	DingNotify(msg)
}
