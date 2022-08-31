package main

import (
	"github.com/gin-gonic/gin"
	"log"
	"redisdemo/utils"
)




func main() {
	gin.SetMode(gin.ReleaseMode)
	router := gin.Default()
	router.POST("/switch", utils.SwitchConfig)

	log.Println("the server is running at 10000 port!!!")
	if router.Run(":10000") != nil {
		log.Println("the server fail to run!!!")
	}
}