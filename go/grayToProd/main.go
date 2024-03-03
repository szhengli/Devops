package main

import (
	"awesomeProject/utils2"
	"fmt"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"net/http"
)

func main() {
	//utils.SyncFull("20240220")
	r := gin.Default()
	r.Use(cors.Default()) // fix cross-domain issue

	r.GET("/ping", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "pong",
		})
	})

	// to be called by gray, with Synced set to false
	//or by prod  with Synced set to true, after  jenkins job after completed

	r.POST("/update", utils2.WebUpdate)

	r.GET("/getAllBranches", utils2.WebGetAllBranches)

	// to get record for branch
	r.GET("/getBranch", utils2.WebGetBranch)
	// sync gray image or html to production, to be invoked by dingding
	r.GET("/syncBranch", utils2.WebSyncBranch)

	err := http.ListenAndServe(":8088", r)
	if err != nil {
		fmt.Println(err)
		return
	}

}
