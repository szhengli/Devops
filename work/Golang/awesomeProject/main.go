package main

import (
	"awesomeProject/utils2"
	"fmt"
	"github.com/gin-contrib/cors"
	"github.com/gin-contrib/sessions"
	"github.com/gin-contrib/sessions/cookie"
	"github.com/gin-gonic/gin"
	"html/template"
	"io/ioutil"
	"net/http"
	"strings"
)

func main() {
	//utils.SyncFull("20240220")
	r := gin.Default()
	r.Use(cors.Default()) // fix cross-domain issue

	t1, err := LoadTemplates()
	if err != nil {
		panic(err)
	}
	r.SetHTMLTemplate(t1)

	store := cookie.NewStore([]byte("secret"))
	r.Use(sessions.Sessions("Authorization", store))

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

	// record the branch of SVN projects in production
	r.POST("/recordBranchInProd", utils2.WebRecordBranchInProd)

	//r.Static("/public", "./public")
	authorized := r.Group("/rollback", gin.BasicAuth(gin.Accounts{
		"admin":   "Password1234",
		"jenkins": "Zhonglun!ef!",
	}))

	authorized.GET("/", func(c *gin.Context) {

		user := c.MustGet(gin.AuthUserKey).(string)

		fmt.Println("$$$$$$$$$$")
		fmt.Println(user)
		authorization := c.Request.Header["Authorization"][0]
		c.SetCookie("Authorization", authorization, 3600, "/rollback", "", false, true)
		fmt.Println("$$$$$$$$$$")
		c.HTML(http.StatusOK, "/templates/index.html", gin.H{
			"Authorization": authorization,
		})
	})
	authorized.POST("/updateProgress", utils2.WebRollbackUpdate)
	authorized.GET("/start", utils2.WebRollback)
	authorized.GET("/buildJob", utils2.WebBuildJob)
	authorized.GET("/getReport", utils2.WebGetRollbackReport)
	authorized.GET("/getReleases", utils2.WebGetReleases)
	authorized.GET("/getReleaseDetails", utils2.WebGetReleaseDetails)

	err = http.ListenAndServe(":8088", r)
	if err != nil {
		fmt.Println(err)
		return
	}

}
func LoadTemplates() (*template.Template, error) {
	t := template.New("")
	for name, file := range Assets.Files {
		if file.IsDir() || !strings.HasSuffix(name, ".html") {
			continue
		}
		h, err := ioutil.ReadAll(file)
		if err != nil {
			return nil, err
		}
		t, err = t.New(name).Parse(string(h))
		if err != nil {
			return nil, err
		}
	}
	return t, nil
}
