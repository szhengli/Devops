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
		log.Println("fail to get synced for: ", key, "  ", err)
		//log.Fatal(err)
		return false
	}
	synced, err := strconv.ParseBool(sync)
	if err != nil {
		log.Println("sync value for: ", key, " fail to convert to bool value, ", err)
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

func syncWithProd(branch, batch string) {

	msg := "分支: " + branch + "  系统: " + batch + " , 服务同步开始，请关注 ...."
	NotifyAlls(msg)

	sep := "[，, ，：:、]"
	services := regexp.MustCompile(sep).Split(batch, -1)

	if len(services) > 0 {
		for _, service := range services {
			strings.TrimSpace(service)
			jenkinsJob := "sync-prodv5-" + service
			err := JenkinsBuild(jenkinsJob)
			if err != nil {
				AddOrModifyRecord(branch, service, true)
				msg := "灰度环境没有部署过" + service + "， 所以无法同步，请人工发布！ 下次不要申请同步这个服务了。"
				NotifyAlls(msg)
			}

		}
	} else {
		log.Println("there is no such service in this branch with the pattern: " + batch + " so skip to syn this kind of jenkins job")
	}
	msg = "正在执行jenkins 同步job:  " + batch + " ......."
	log.Println(msg)
}

/**
func isSynced(branch, batch string) {
	sep := "[，, ，：:、]"
	services := regexp.MustCompile(sep).Split(batch, -1)
	total := len(services)
	var completed []string

	if total > 0 {
		for {
			counter := 0
			for _, service := range services {
				strings.TrimSpace(service)
				key := branch + ":" + service
				if getSyncedValue(key) {
					if !slices.Contains(completed, key) {
						completed = append(completed, key)
						msg := "分支: " + branch + "  系统: " + service + " 服务同步完成. !!!!!"
						NotifyAlls(msg)
					}
					msg := service + " is  synced !!!!!!!!!!!!!!!!!"
					log.Println(msg)
					counter = counter + 1
				} else {
					log.Println(service + " is NOT synced .........")
				}
			}

			if total == counter {
				msg := "分支: " + branch + "  系统: " + batch + " , 服务同步完成. !!!!!"
				NotifyAlls(msg)
				return
			}
			time.Sleep(2 * time.Second)
		}

	}

}

/
*/

func isSynced(branch, batch string) {
	sep := "[，, ，：:、]"
	services := regexp.MustCompile(sep).Split(batch, -1)

	for {

		for _, service := range services {
			service = strings.TrimSpace(service)
			key := branch + ":" + service
			if getSyncedValue(key) {
				msg := "分支: " + branch + "  系统: " + service + " 服务同步完成. !!!!!"
				services = removeElement(services, service)
				NotifyAlls(msg)
			} else {
				log.Println(service + " is NOT synced .........")
			}
		}

		if len(services) == 0 {
			msg := "分支: " + branch + "  系统: " + batch + " , 服务同步完成. !!!!!"
			NotifyAlls(msg)
			return
		}

		time.Sleep(2 * time.Second)
	}

}

func SyncFull(branch, batchList string) {

	sep := "[;；]"
	batches := regexp.MustCompile(sep).Split(batchList, -1)

	for _, batch := range batches {
		if len(batch) != 0 {
			go syncWithProd(branch, batch)
			//println("+++" + batch + "++++")
			isSynced(branch, batch)
		}
	}
	msg := "分支: " + branch + "  系统: " + batchList + " , 服务已经全部同步成功. !!!!!！！！！！！"
	log.Println(msg)

}

func NotifyAlls(msg string) {
	log.Println(msg)
	DingNotify(msg)

}

// record the branch of SVN projects in production

func RecordBranchInProd(service, branch string) {
	rdb, ctx := ConnectRedis()
	key := "prod:" + service
	status := rdb.Set(ctx, key, branch, 0)
	_, err := status.Result()

	if err != nil {
		panic(err)
	}
	fmt.Println("record the branch of service in production  successfully:  " + key)
}

func NeedRollback(service, curBranch string) bool {
	BranchInProd, _ := GetBranchInProd(service)

	if BranchInProd == curBranch {
		return true
	}
	return false
}

func GetBranchInProd(service string) (string, error) {
	rdb, ctx := ConnectRedis()
	key := "prod:" + service
	res := rdb.Get(ctx, key)
	branch, err := res.Result()

	if err != nil {
		fmt.Println("no branch record for", service)
		return "", err
	}

	fmt.Println(service, "branch:", branch)
	fmt.Println("get record the branch of service in production  successfully:  " + key)
	return branch, nil
}
