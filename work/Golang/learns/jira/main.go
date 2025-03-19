package main

import (
	"fmt"
	jira "github.com/maksymsv/go-jira"
)

func main() {
	tp := jira.BasicAuthTransport{
		Username: "zhengli",
		Password: "111111",
	}

	client, err := jira.NewClient(tp.Client(), "https://jira.cnzhonglunnet.com")

	if err != nil {
		panic(err)
	}

	list, _, err := client.Role.GetList()
	if err != nil {
		panic(err)
		return
	}

	fmt.Println(list)
}
