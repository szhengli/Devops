package utils

import (
	"github.com/goex-top/dingding"
	"strings"
	"text/template"
)

const (
	keyword   = "[prod]  "
	startTmpl = `分支: {{.Branch}},  系统: {{.Services}} , 服务开始同步，请关注 ...`
	endTmpl   = `分支: {{.Branch}},  系统: {{.Services}} , 服务开始同步，请关注 !!!!!`
)

type Release struct {
	Branch   string
	Services string
}

func DingNotify(msg string) {
	var (
		// DING_URL = "https://oapi.dingtalk.com/robot/send?access_token=c9cc7138a22bd46cc3bec04f4e916320c8d33ba48374eb33533bc053927022eb"
		token = "c9cc7138a22bd46cc3bec04f4e916320c8d33ba48374eb33533bc053927022eb"
		ding  = dingding.Ding{token}
	)
	message := dingding.Message{Content: keyword + msg}
	ding.SendMessage(message)
}

func GetMsg(tmpl string, release *Release) string {
	tmp := template.Must(template.New("zl").Parse(tmpl))
	res := strings.Builder{}
	err := tmp.Execute(&res, release)
	if err != nil {
		return ""
	}
	//log.Println(res.String())
	return res.String()
}
