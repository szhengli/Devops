package utils

import (
	"github.com/gin-gonic/gin"
	"text/template"

	"log"
	"os"
)

type Nginx struct {
	ShortDomain string `json:"shortDomain"`
	Enable      bool   `json:"enable"`    // if true it will switch to backup env.
}

const TEMPLATE = `  

include /data/pro/nginx/switch_conf/{{ . }} ; 

`

func configPath(shortDomain string, enable bool) string {
	if enable {
		return shortDomain + "-backup.conf"
	}
	return shortDomain + "-normal.conf"
}

func isInvalidDomain(shortDomain string) bool {
	var valid_domain_list = [...]string{"yxlpos", "pos", "ls"}
	log.Println(shortDomain)
	for _, domain := range valid_domain_list {
		if domain == shortDomain {
			log.Println("good domain ****")
			return false
		}
	}
	log.Println("bad domain !!!!!!")
	return true
}

func SwitchConfig(c *gin.Context) {
	var nginx Nginx

	if c.ShouldBindJSON(&nginx) == nil {
		if isInvalidDomain(nginx.ShortDomain) {
			c.JSON(400, gin.H{"switch": 0, "reason": "Invalid domain, that  must be yxlpos, pos, or ls !"})
			return
		}


		adjustService(nginx.Enable)   // adjust the number of pods in backup.


		configfile := configPath(nginx.ShortDomain, nginx.Enable)
		if tmpl, err := template.New("config").Parse(TEMPLATE); err == nil {
			config, _ := os.OpenFile(nginx.ShortDomain+".conf", os.O_CREATE|os.O_WRONLY, os.ModePerm)
			defer func(config *os.File) {
				err := config.Close()
				if err != nil {
					log.Println("Fail to close config file.")
				}
			}(config)

			if tmpl.Execute(config, configfile) != nil {
				log.Println("Fail to create  the switch config file!")
				c.JSON(400, gin.H{"switch": 0, "reason": "Fail to create  the switch config file!"})
				return
			}
			if nginx.Enable {
				log.Println("switch to backup config fle!")
				c.JSON(200, gin.H{"switch": 1, "reason": "success"})
				return
			} else {
				log.Println("switch to normal config fle!")
				c.JSON(200, gin.H{"switch": 0, "reason": "success"})
				return
			}

		} else {
			log.Println("Fail parse template.")
			c.JSON(400, gin.H{"switch": 0, "reason": "Fail parse template."})
			return
		}

	} else {
		c.JSON(400, gin.H{"switch": 0, "reason": "wrong input format"})
	}

}
