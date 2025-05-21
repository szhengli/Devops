package utils2

import (
	"fmt"
	gojenkins "github.com/yosida95/golang-jenkins"
	"net/url"
	"strings"
)

const (
	JENKINS_TEST_URL      = "http://192.168.1.121:8080/"
	JENKINS_TEST_USERNAME = "zhengli"
	JENKINS_TEST_TOKEN    = "11459b96702fa7ed04759c034c99551fbc"
	JENKINS_PROD_URL      = "http://172.19.125.135:8080/"
	JENKINS_PROD_USERNAME = "admin"
	JENKINS_PROD_TOKEN    = "11bbd62e96c8390d2920a2d6bcd24696fb"
)

//var V5Services = []string{"datascreen_h5", "wshop_h5", "zleditor"}

func UpdateRollbackRecord(dingID, service string, state string) {
	rdb, ctx := ConnectRedis()

	rdb.HSet(ctx, dingID, service, state)

	fmt.Println("add or update record successfully:  " + dingID + " " + service + " " + state)
}

func JenkinsRollback(dingID, service string, params url.Values) error {
	auth := &gojenkins.Auth{
		Username: JENKINS_PROD_USERNAME,
		ApiToken: JENKINS_PROD_TOKEN,
	}
	jobName := ""
	//if strings.Contains(service, "v5") || strings.Contains(service, "yxl") || slices.Contains(V5Services, service) {
	if strings.HasSuffix(service, "v5") || strings.HasSuffix(service, "v5_h5") {
		jobName = "prodv5-prodv5-" + service + "-rollback"
		fmt.Println(jobName)
	} else {
		jobName = "prod-prod-" + service + "-rollback"
		fmt.Println(jobName)
	}

	jenkins := gojenkins.NewJenkins(auth, JENKINS_PROD_URL)
	job, err := jenkins.GetJob(jobName)
	if err != nil {
		UpdateRollbackRecord(dingID, service, "unsupported")
		msg := service + "回滚不支持。可能原因：只支持回滚Jenkins部署的JAVA后端项目和前端服务器服务的前端项目"
		println(msg)
		DingNotifyRollback(msg)
		fmt.Println("!!!!!!!!!!!!!!!!!!!!!")
		fmt.Println(err)
		fmt.Println("!!!!!!!!!!!!!!!!!!!!!")
		return err
	}
	fmt.Println("######################")

	err = jenkins.Build(job, params)
	if err != nil {
		msg := err.Error()
		if strings.Contains(msg, "Created") {
			UpdateRollbackRecord(dingID, service, "rollbacking")
			return nil
		} else {
			return err
		}
	}
	fmt.Println("######################")
	return nil
}

func JenkinsBuild(jobName string) error {
	auth := &gojenkins.Auth{
		Username: JENKINS_PROD_USERNAME,
		ApiToken: JENKINS_PROD_TOKEN,
	}

	//jobName := "sitv5-zl-fpv5-jiagou-gray"
	jenkins := gojenkins.NewJenkins(auth, JENKINS_PROD_URL)
	job, err := jenkins.GetJob(jobName)
	if err != nil {
		println("fail to get job .............r")
		return err
	}

	err = jenkins.Build(job, nil)
	msg := err.Error()
	if strings.Contains(msg, "Created") {
		return nil
	}
	return err
}
