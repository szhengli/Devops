package utils2

import (
	"awesomeProject/utils"
	"fmt"
	"github.com/gin-gonic/gin"
	"log"
)

type Record struct {
	Branch  string `json:"branch"`
	Service string `json:"service"`
	Synced  bool   `json:"synced"`
}

// to be called by gray, with Synced set to false
//or by prod  with Synced set to true, after  jenkins job after completed

func WebUpdate(ctx *gin.Context) {
	var record Record
	if ctx.ShouldBind(&record) == nil {
		log.Println(record.Branch)
		log.Println(record.Service)
		log.Println(record.Synced)
		AddOrModifyRecord(record.Branch, record.Service, record.Synced)
	}
	ctx.String(200, "Success")
}

func WebGetAllBranches(ctx *gin.Context) {
	branches, err := utils.GetAllBranches()
	if err != nil {
		ctx.JSON(409, gin.H{"error": err})
		return
	}
	ctx.JSON(200, gin.H{"branches": branches})
}

// to get record for branch
func WebGetBranch(ctx *gin.Context) {
	branch := ctx.Query("branch")
	if len(branch) != 8 {
		ctx.JSON(406, gin.H{"error": "Invalid branch!"})
		return
	}
	details, err := utils.FindBranchDetails(branch)
	if err != nil {
		ctx.JSON(409, gin.H{"error": err})
		return
	}
	ctx.JSON(200, gin.H{"details": details})
}

// sync gray image or html to production, to be invoked by dingding
func WebSyncBranch(ctx *gin.Context) {
	branch := ctx.Query("branch")
	sysops := ctx.Query("sysops")
	if len(branch) != 8 {
		ctx.JSON(406, gin.H{"error": "Invalid branch!"})
		return
	}

	log.Println("!!!!!!!!!!!!!!!!!!!!!")
	fmt.Println(branch)
	fmt.Println(sysops)
	log.Println("!!!!!!!!!!!!!!!!!!!!!")

	go SyncFull(branch,sysops)
	ctx.JSON(200, gin.H{"msg": "start syncing to production !"})
}
