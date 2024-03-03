package utils2

import (
	"context"
	"fmt"
	"github.com/redis/go-redis/v9"
	"log"
	"regexp"
	"strconv"
	"strings"
	"time"
)

type ErrorNoRecord struct {
}

func (e *ErrorNoRecord) Error() string {
	return "No records for the branch"
}

var redisAddr = "r-uf6s3j8oimh0g3lvgb.redis.rds.aliyuncs.com:6379"

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
	res := rdb.HGet(ctx, key, "synced")
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
func AddOrModifyRecord(branch, service string, synced bool) {
	rdb, ctx := ConnectRedis()
	key := branch + ":" + service
	status := rdb.HSet(ctx, key, "synced", synced)
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

func syncWithProd(batch string) {
	sep := "[，, ，：:]"
	services := regexp.MustCompile(sep).Split(batch, -1)

	if len(services) > 0 {
		for _, service := range services {
			strings.TrimSpace(service)
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
		fmt.Println("there is no such service in this branch with the pattern: " + batch + " so skip to syn this kind of jenkins job")
	}
	msg := "executing jenkins job for " + batch + " ################"
	NotifyAlls(msg)
}

func invokeJenkinsJob(jenkinsJob, branchAndType, service string) {
	println(jenkinsJob + "started ")

	time.Sleep(4 * time.Second) // simulate the real jenkins job execution

	// branchAndType, for  sample 20240220:java or  20240220:html
	AddOrModifyRecord(branchAndType, service, true)
}

func isSynced(branch, batch string) {
	sep := "[，, ，：:]"
	services := regexp.MustCompile(sep).Split(batch, -1)
	total := len(services)

	if total > 0 {
		for {
			counter := 0
			for _, service := range services {
				strings.TrimSpace(service)
				key := branch + ":" + service
				if getSyncedValue(key) {
					fmt.Println(service + "is  synced !!!!!!!!!!!!!!!!!")
					counter = counter + 1
				} else {
					fmt.Println(service + " is NOT synced .........")
				}
			}

			if total == counter {
				fmt.Println(branch + "  " + batch + ": is all synced")
				return
			}
			time.Sleep(2 * time.Second)
		}

	}

}

func SyncFull(branch, batchList string) {

	/*	batchList := `omsv4,      stmsv5,umsv5  ;
		mbmsv5,zkmsv5, posmsv5  ;
		yxlweb    ，     yxlmall     ; `
	*/
	sep := "[;；]"
	batches := regexp.MustCompile(sep).Split(batchList, -1)

	for _, batch := range batches {
		if len(batch) != 0 {
			go syncWithProd(batch)
			//println("+++" + batch + "++++")
			isSynced(branch, batch)
			msg := "[" + branch + "]" + ": " + batch + "synced successfully !"
			log.Println(msg)
			NotifyAlls(msg)
		}
	}
	msg := "[" + branch + "]" + ": " + batchList + " have  been ALL synced successfully !!!!"
	NotifyAlls(msg)

}

func NotifyAlls(msg string) {

	msg = keyword + "  " + msg
	log.Println(msg)
	DingNotify(msg)

}
