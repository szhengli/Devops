package utils

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
)

const ()

// 钉钉Markdown消息结构体
type DingTalkMarkdownMessage struct {
	Msgtype  string    `json:"msgtype"`
	Markdown *Markdown `json:"markdown"`
	At       *At       `json:"at,omitempty"`
}

type Markdown struct {
	Title string `json:"title"`
	Text  string `json:"text"`
}

type At struct {
	AtMobiles []string `json:"atMobiles,omitempty"`
	IsAtAll   bool     `json:"isAtAll,omitempty"`
}

// 发送钉钉消息
func SendDingTalkMessage(webhookURL string, message *DingTalkMarkdownMessage) error {
	payload, err := json.Marshal(message)
	if err != nil {
		return err
	}

	resp, err := http.Post(webhookURL, "application/json", bytes.NewBuffer(payload))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("dingtalk api returned status: %d", resp.StatusCode)
	}

	return nil
}
