package utils2

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"log"
	"strings"
)

type Record struct {
	Branch  string `json:"branch"`
	Service string `json:"service"`
	Synced  bool   `json:"synced"`
}

type ServiceRecord struct {
	Service string `json:"service"`
	Branch  string `json:"branch"`
}

func WebBuildJob(ctx *gin.Context) {
	service := ctx.Query("service")
	action := ctx.Query("action")
	jobName := ""
	prefix := ""
	//if strings.Contains(service, "v5") || strings.Contains(service, "yxl") || slices.Contains(V5Services, service) {
	if strings.HasSuffix(service, "v5") || strings.HasPrefix(service, "v5_h5") {
		prefix = "prodv5-prodv5-" + service
		fmt.Println(prefix)
	} else {
		prefix = "prod-prod-" + service 
		fmt.Println(prefix)
	}
	if action == "rollback" {
		jobName = prefix + "-rollback"
	} else if action == "restart" {
		jobName = prefix + "-restart"
	}
	/**
	err := JenkinsBuild(jobName)
	if err != nil {
		fmt.Println(err)
		ctx.JSON(400, err.Error())
		return
	}

	*/
	ctx.JSON(200, "相关jenkins job "+jobName+"正在执行")
}

func WebGetReleaseDetails(ctx *gin.Context) {
	dingID := ctx.Query("dingID")
	allRelease, err := GetReleaseDetails(dingID)
	if err != nil {
		fmt.Println(err)
		ctx.JSON(400, allRelease)
		return
	}
	ctx.JSON(200, allRelease)
}

func WebGetReleases(ctx *gin.Context) {
	allRelease := GetReleases()
	ctx.JSON(200, allRelease)
}

func WebGetRollbackReport(ctx *gin.Context) {
	dingID := ctx.Query("dingID")
	report, err := GetRollbackReport(dingID)
	if err != nil {
		fmt.Println(err)
		ctx.JSON(400, err)
	} else {
		ctx.JSON(200, report)
	}

}

func WebRollback(ctx *gin.Context) {
	dingID := ctx.Query("dingID")
	Rollback(dingID)
	DingNotifyRollback("发布单/回滚单：" + dingID + "，已经开始回滚。")
	ctx.String(200, "发布单/回滚单："+dingID+"，已经开始回滚。详情查看钉钉群【项目发布专用群】 !")
}

func WebRollbackUpdate(ctx *gin.Context) {
	var record RollbackRecord
	if ctx.ShouldBind(&record) == nil {
		log.Println(record.DingID)
		log.Println(record.Service)
		log.Println(record.State)
		UpdateRollbackRecord(record.DingID, record.Service, record.State)
	}
	ctx.String(200, "Successfully updated the rollbackRecord!")
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
	branches, err := GetAllBranches()
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
	details, err := FindBranchDetails(branch)
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

	go SyncFull(branch, sysops)
	ctx.JSON(200, gin.H{"msg": "start syncing to production !"})
}

// record the branch of SVN projects in production

func WebRecordBranchInProd(ctx *gin.Context) {
	var record ServiceRecord
	if ctx.ShouldBind(&record) == nil {
		fmt.Println("!!!!!!!!!!!!!!!!!!")
		fmt.Println(record.Service)
		fmt.Println(record.Branch)
		fmt.Println("!!!!!!!!!!!!!!!!!!")
		RecordBranchInProd(record.Service, record.Branch)
		ctx.String(200, "Success")
	} else {
		ctx.String(407, "参数错误，请带上SVN项目名和分支号")
	}

}
