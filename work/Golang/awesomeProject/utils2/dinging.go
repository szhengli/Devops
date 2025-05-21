package utils2

import (
	"github.com/goex-top/dingding"
)

func DingNotify(msg string) {
	var (
		// DING_URL = "https://oapi.dingtalk.com/robot/send?access_token=c9cc7138a22bd46cc3bec04f4e916320c8d33ba48374eb33533bc053927022eb"
		//token = "c9cc7138a22bd46cc3bec04f4e916320c8d33ba48374eb33533bc053927022eb"
		//token = "0b59ceb27a3de5f26b7f58c401027699e6a392a573ec82e6d98ac986a09621b9"
		token = "3b98d4511a79b7d6e903a785604bae4231167516b41f05d8b5e2949ffe78de0d"
		ding  = dingding.Ding{token}
	)
	//message := dingding.Message{Content: msg}
	message := dingding.Message{Content: msg}
	//fmt.Println(msg)
	ding.SendMessage(message)
	//log.Println(result.ErrMsg)
}

func DingNotifyRollback(msg string) {
	var (
		// DING_URL = "https://oapi.dingtalk.com/robot/send?access_token=c9cc7138a22bd46cc3bec04f4e916320c8d33ba48374eb33533bc053927022eb"
		//token = "c9cc7138a22bd46cc3bec04f4e916320c8d33ba48374eb33533bc053927022eb"
		//token = "0b59ceb27a3de5f26b7f58c401027699e6a392a573ec82e6d98ac986a09621b9"
		token = "b6425c2040004b17c9df756158a2d25b695e278906f522b7f2ba4c3c3e0f7f2d"
		ding  = dingding.Ding{token}
	)
	//message := dingding.Message{Content: msg}
	message := dingding.Message{Content: msg}
	//fmt.Println(msg)
	ding.SendMessage(message)
	//log.Println(result.ErrMsg)
}
