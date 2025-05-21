package utils2

import (
	"encoding/json"
	"fmt"
	"github.com/go-acme/lego/v4/log"
	"net/url"
	"strings"
	"time"
)

type ReleaseRecord struct {
	DingID      string   `json:"dingID"`
	Branch      string   `json:"branch"`
	ServiceList []string `json:"serviceList"`
}

type RollbackReport struct {
	DingID  string     `json:"dingID"`
	Records []RbRecord `json:"records"`
}

type RollbackRecord struct {
	DingID  string `json:"dingID"`
	Service string `json:"service"`
	State   string `json:"state"`
}

type RbRecord struct {
	Service string `json:"service"`
	State   string `json:"state"`
}

func GetReleaseDetails(dingID string) (ReleaseRecord, error) {
	r, ctx := ConnectRedis()
	key := "release:" + dingID
	res := r.HGetAll(ctx, key)
	releaseMap, _ := res.Result()
	var releaseRcord ReleaseRecord
	services := releaseMap["serviceList"]
	serviceList := []string{}
	err := json.Unmarshal([]byte(services), &serviceList)
	if err != nil {
		return ReleaseRecord{}, err
	}
	releaseRcord.ServiceList = serviceList
	releaseRcord.Branch = releaseMap["branch"]
	releaseRcord.DingID = dingID
	return releaseRcord, nil
}

func GetReleases() []string {
	r, ctx := ConnectRedis()
	res := r.Keys(ctx, "release:*")
	releaseList, _ := res.Result()
	var releases []string

	for _, release := range releaseList {
		releases = append(releases, strings.TrimPrefix(release, "release:"))
	}
	return releases
}

func GetRollbackReport(dingID string) (RollbackReport, error) {
	r, ctx := ConnectRedis()

	res := r.HGetAll(ctx, dingID)
	Records := []RbRecord{}

	details, err := res.Result()
	if err != nil {
		return RollbackReport{}, err
	}

	for service, state := range details {
		Records = append(Records, RbRecord{Service: service, State: state})
	}

	rollbackReport := RollbackReport{DingID: dingID, Records: Records}

	return rollbackReport, nil
}

func Rollback(dingID string) {
	red, ctx := ConnectRedis()
	key := "release:" + dingID

	res := red.HGetAll(ctx, key)
	release, _ := res.Result()
	services := release["serviceList"]
	curBranch := release["branch"]

	serviceList := []string{}

	err := json.Unmarshal([]byte(services), &serviceList)
	if err != nil {
		fmt.Println("fail to convert")
		return
	}

	serviceListToBeChecked := serviceList

	fmt.Println("***************dingID, curBranch**************")
	fmt.Println(dingID)
	fmt.Println(curBranch)
	fmt.Println("*****************************")
	params := url.Values{"dingID": []string{dingID}}

	for _, service := range serviceList {

		if NeedRollback(service, curBranch) {
			err = JenkinsRollback(dingID, service, params)
		} else {
			msg := service + "最近未发布，不需要回滚！"
			serviceListToBeChecked = removeElement(serviceList, service)
			DingNotifyRollback(msg)
		}

		if err != nil {
			fmt.Println(err)
		}
	}
	fmt.Println(serviceListToBeChecked, " will be checked if they have been rollbacked!")
	go IsRollbacked(dingID, serviceListToBeChecked)

}

func IsRollbacked(dingID string, serviceList []string) {

	for {
		for _, service := range serviceList {
			service = strings.TrimSpace(service)
			state, err := getServiceRollbackState(dingID, service)
			if err != nil {
				return
			}

			if state == "unsupported" || state == "completed" {
				msg := "系统: " + service + " 回滚完成. !!!!!"
				serviceList = removeElement(serviceList, service)
				log.Println(msg)
				//NotifyAlls(msg)
			} else {
				log.Println(service + " is NOT synced .........")
			}
		}

		if len(serviceList) == 0 {
			msg := "发布单" + dingID + "相关服务回滚完成. !!!!!"
			log.Println(msg)
			//NotifyAlls(msg)
			return
		}

		time.Sleep(2 * time.Second)
	}

}

func getServiceRollbackState(dingID, service string) (string, error) {
	rdb, ctx := ConnectRedis()
	res := rdb.HGet(ctx, dingID, service)
	state, err := res.Result()
	if err != nil {
		log.Println("fail to get rollback service state for: ", dingID, service, "  ", err)
		//log.Fatal(err)
		return "", err
	}

	return state, err
}
