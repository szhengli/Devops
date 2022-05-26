package utils

import (
	"fmt"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"sync"
)



func StartWeb(){
	r := gin.Default()
	corsCfg := cors.DefaultConfig()
	corsCfg.AllowOrigins = []string{
		"*",
	}
	r.Use(cors.New(corsCfg))

	r.POST("/ping", func(context *gin.Context) {
		var service Service

		err := context.BindJSON(&service)

		if err != nil {
			return
		}

		context.JSON(200, service)
	})
	r.POST("/ping2", func(context *gin.Context) {

		context.PureJSON(200, gin.H{
			"html": "<b>Hello, world!</b>",
		})

	})


	r.POST("/applyProject", func(context *gin.Context) {
		var service Service
		var wg sync.WaitGroup
		var count = 1
		defer wg.Wait()

		result := map[string] bool{}
		defer context.JSON(200, result)

		resChan := make(chan map[string]bool, 1 )
		defer close(resChan)

		err := context.BindJSON(&service)
		if err != nil {
			return
		}

		go func() {
			print("########## svn ########\n")
			wg.Add(1)
			defer wg.Done()
			fmt.Println(service)
		    okSvn :=AddSvnProject(service)
			//time.Sleep(8*  time.Second)
			//okSvn:=true
			if okSvn {
				resChan <- map[string]bool{
					"svn" : true,
				}
			}else {
				resChan <- map[string]bool{
					"svn" : false,
				}
			}
		}()

		if service.DnsName != "" {
			print("######### dns ######### \n")
			count += 1

			go func() {
				wg.Add(1)
				defer wg.Done()
				okSite := AddSite(service)
				//time.Sleep(4*  time.Second)
				//okSite := true
				if okSite {
					resChan <- map[string]bool{
						"site" : true,
					}
				}else {
					resChan <- map[string]bool{
						"site" : false,
					}
				}
			}()
		}

		if service.Level != ""  {
			count += 2
			fmt.Println("########## redis ########\n")

			go func() {
				wg.Add(1)
				defer wg.Done()
				okRedis := CreateRedisCluster(service.Level,service.Name)
				//time.Sleep(4*  time.Second)
			//	okRedis := false
				if okRedis {
					resChan <- map[string]bool{
						"redis" : true,
					}
				}else {
					resChan <- map[string]bool{
						"redis" : false,
					}
				}
			}()

			go func() {
				fmt.Println("########## mq ########\n")
				wg.Add(1)
				defer wg.Done()
				okMQTopic :=TopicApply(service.Level, service.Name)
			//	time.Sleep(10*  time.Second)
			//	okMQTopic := true
				if okMQTopic {
					fmt.Println("mq++++++++++1")
					resChan <- map[string]bool{
						"mq" : true,
					}
				}else {
					fmt.Println("mq------------1")
					resChan <- map[string]bool{
						"mq" : false,
					}
				}
			}()
		}

		fmt.Println("******* count *******")
		fmt.Println(count)
		fmt.Println("**************")

		for i:=0; i<count; i++ {
			select {
			case res := <-resChan:
				for k, v := range res {
					result[k]=v
				}
			}
		}
		fmt.Println(result)
	})

	r.Run()
}