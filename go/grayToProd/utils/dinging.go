package utils

import "github.com/goex-top/dingding"

const keyword = "[prod]  "

func DingNotify(msg string) {
	var (
		// DING_URL = "https://oapi.dingtalk.com/robot/send?access_token=c9cc7138a22bd46cc3bec04f4e916320c8d33ba48374eb33533bc053927022eb"
		token = "c9cc7138a22bd46cc3bec04f4e916320c8d33ba48374eb33533bc053927022eb"
		ding  = dingding.Ding{token}
	)
	message := dingding.Message{Content: keyword + msg}
	ding.SendMessage(message)
}
