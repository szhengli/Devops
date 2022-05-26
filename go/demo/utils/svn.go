package utils

import (
	"fmt"
	"os/exec"
	"time"
)

func AddSvnProject( service Service ) (ok bool) {

	start := time.Now().Unix()
	place := "svn"
	cmd := exec.Command("/usr/bin/createSvn.sh", place, service.Name, service.SvnClass)
	err := cmd.Run()
	end2 := time.Now().Unix()
	if err != nil {
		fmt.Println("fail to add empty project in svn trunk ")
		return false
	}
	fmt.Println("^^^^^^^^^^^^")
	fmt.Println(end2-start)
	fmt.Println("^^^^^^^^^^^^")
	return true
}
