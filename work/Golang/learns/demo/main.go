package main

import (
	"fmt"
	"learns/demo/utils"
)

func main() {
	message := utils.PrepareReport()
	err := utils.SendDingTalkMessage(utils.WebhookURL, message)
	if err != nil {
		fmt.Printf("发送失败: %v\n", err)
		return
	}
	fmt.Println("消息发送成功")
}
