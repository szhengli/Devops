package utils

import (
	"fmt"
	"os/exec"
	"time"
)



func AddSite( service Service ) (ok bool) {
	start := time.Now().Unix()
	place := "192.168.3.81"
	cmd := exec.Command("/usr/bin/createNginx.sh", place, service.DnsName, service.Level)
	err := cmd.Run()
	end2 := time.Now().Unix()
	if err != nil {
		fmt.Println("fail to add virtual site in nginx ")
		return false
	}
	fmt.Println("^^^^^^^^^^^^")
	fmt.Println(end2-start)
	fmt.Println("^^^^^^^^^^^^")
	return true
}
