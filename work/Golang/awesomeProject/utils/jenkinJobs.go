package utils

import (
	gojenkins "github.com/yosida95/golang-jenkins"
	"strings"
)

const (
	JENKINS_TEST_URL      = "http://192.168.1.121:8080/"
	JENKINS_TEST_USERNAME = "zhengli"
	JENKINS_TEST_TOKEN    = "11459b96702fa7ed04759c034c99551fbc"

	JENKINS_PROD_URL      = "http://172.19.233.38:8080/"
	JENKINS_PROD_USERNAME = "admin"
	JENKINS_PROD_TOKEN    = "11bbd62e96c8390d2920a2d6bcd24696fb"
)

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
