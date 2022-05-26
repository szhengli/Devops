package utils

import (
	"bytes"
	"fmt"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

//usage Sample:  utils.CreateRedisCluster("rdv5_simv5_zt","carTest")

func CreateRedisCluster(place , name string) (ok bool) {

	start := time.Now().Unix()
    // poll allover all redis service and get the available port.
	cmd := exec.Command("/usr/bin/findport","all")
	var result bytes.Buffer
	cmd.Stdout = &result
	err := cmd.Run()
	if err != nil {
		fmt.Println(err)
		return false
	}

	_, err = strconv.Atoi(strings.TrimSpace(result.String()))
	if err != nil {
		fmt.Println("fail to convert to number")
		return false
	}

	fmt.Println(strings.TrimSpace(result.String()))
    port := strings.TrimSpace(result.String())

	if strings.HasSuffix(name, "v5")  {
		cmd = exec.Command("/usr/bin/createRedis.sh", place, name ,port)
	}else {
		cmd = exec.Command("/usr/bin/createRedis.sh", "v3", name ,port)
	}
	err = cmd.Run()
	end2 := time.Now().Unix()
	if err != nil {
		fmt.Println("fail to create cluster")
		return false
	}

	fmt.Println("^^^^^^^^^^^^")
	fmt.Println(end2-start)
	fmt.Println("^^^^^^^^^^^^")

	return true


}
