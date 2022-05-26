package utils

import (
	"bytes"
	"fmt"
	"github.com/go-redis/redis"
	"os/exec"
	"strings"
	"sync"
)

func TopicApply(level , name string) (ok bool) {

		ok,serverList := GetMqServers(level, name)
		if ok {
			fmt.Println("creating topic")
			CreateTopic(serverList, "topic_"+name)
			return true
		}else {
			fmt.Println("fail to retrive the server list")
			return false
		}

}

func GetMqServers(level , name string) ( bool, map [string][]string) {

	rdb := redis.NewFailoverClient(&redis.FailoverOptions{
			MasterName: "release_master_1",
			SentinelAddrs: []string{"192.168.1.32:17020","192.168.1.33:17020","192.168.1.34:17020"},
		})
	envMQServers := make(map[string][]string)

	getV3MQservers := func() map[string][]string{
		envMqList, err := rdb.Keys("rkmq:v3:*").Result()
		if err !=nil {
			fmt.Println(err)
		}
		for _, envMq := range envMqList {
			mqServers, _ := rdb.SMembers(envMq).Result()
			envMQServers[envMq] = mqServers
		}
		return envMQServers
	}

	getV5MQServers := func(level string)  map[string][]string {
		envMqList, err := rdb.Keys("rkmq:v5:" + level +":*").Result()
		if err !=nil {
			fmt.Println(err)
		}
		for _, envMq := range envMqList {
			mqServers, _ := rdb.SMembers(envMq).Result()
			envMQServers[envMq] = mqServers
		}
		return  envMQServers
	}

	if strings.HasSuffix(name, "v5")  {
		return  true, getV5MQServers(level)
	}else {
		return true, getV3MQservers()
	}

}

func CreateTopic(envMQServers map[string] []string , name string ) {
	var wgouter sync.WaitGroup
	wgouter.Add(len(envMQServers))
	defer wgouter.Wait()

	for env, serverList := range envMQServers {
		go func(env string, serverList []string) {
			defer wgouter.Done()
			var brokerList []string
			var nameservers string
			for _, broker := range serverList {
				brokerList = append(brokerList, broker+":10911")
				nameservers = broker + ":9876;" + nameservers
			}

			var wg sync.WaitGroup
			wg.Add(3)
			defer wg.Wait()

			for _, broker := range brokerList {
				broker := broker
				go func(nameservers, env string, wg *sync.WaitGroup) {
					defer wg.Done()
					cmd := exec.Command("/data/alibaba-rocketmq/bin/mqadmin", "updateTopic", "-b", broker, "-t", name, "-n", nameservers)
					var result bytes.Buffer
					cmd.Stdout = &result
					err := cmd.Run()
					if err != nil {
						fmt.Println(err)
					}
					fmt.Println(result.String()  + "   " + broker )
				}(nameservers, env, &wg)
			}

		}(env, serverList)
	}
}