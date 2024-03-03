package utils2

import "github.com/goex-top/dingding"

const keyword = "[生产环境]  "

func DingNotify(msg string) {
	var (
		// DING_URL = "https://oapi.dingtalk.com/robot/send?access_token=c9cc7138a22bd46cc3bec04f4e916320c8d33ba48374eb33533bc053927022eb"
		//token = "c9cc7138a22bd46cc3bec04f4e916320c8d33ba48374eb33533bc053927022eb"
		token = "0b59ceb27a3de5f26b7f58c401027699e6a392a573ec82e6d98ac986a09621b9"
		ding  = dingding.Ding{token}
	)
	message := dingding.Message{Content: keyword + msg}
	ding.SendMessage(message)
}
