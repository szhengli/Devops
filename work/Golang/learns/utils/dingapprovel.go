package main

import (
	"bytes"
	"context"
	"fmt"
	"github.com/goccy/go-json"
	"github.com/open-dingtalk/dingtalk-stream-sdk-go/client"
	"github.com/open-dingtalk/dingtalk-stream-sdk-go/event"
	"github.com/open-dingtalk/dingtalk-stream-sdk-go/logger"
	"github.com/open-dingtalk/dingtalk-stream-sdk-go/payload"
	"io/ioutil"
	"log"
	"net/http"
)

type TokenResponse struct {
	AccessToken string `json:"access_token"`
	ExpiresIn   int    `json:"expires_in"`
}

var (
	clientId     = "dingwlbxkszqgzmmkc3t"
	clientSecret = "8BR5pnPjWMmA5VAAW99DRy8zzHrlqmTP7feamqdE4VfkRevZjUoALJDFGHjex-yM"
)

func getAccessToken(appKey, appSecret string) (string, error) {
	url := fmt.Sprintf("https://oapi.dingtalk.com/gettoken?appkey=%s&appsecret=%s", appKey, appSecret)
	resp, err := http.Get(url)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	var tokenResp TokenResponse
	err = json.Unmarshal(body, &tokenResp)
	if err != nil {
		return "", err
	}

	return tokenResp.AccessToken, nil
}

type GetApprovalResponse struct {
	// 根据钉钉返回的结构体定义解析字段
	Errcode         int             `json:"errcode"`
	Errmsg          string          `json:"errmsg"`
	ProcessInstance json.RawMessage `json:"process_instance"`
}

func getApprovalDetails(accessToken, processInstanceId string) (*GetApprovalResponse, error) {
	url := fmt.Sprintf("https://oapi.dingtalk.com/topapi/processinstance/get?access_token=%s", accessToken)
	fmt.Println(url)
	// 请求体
	requestBody := map[string]string{
		"process_instance_id": processInstanceId,
	}

	jsonBody, err := json.Marshal(requestBody)
	if err != nil {
		fmt.Println("create request body ..........")
		return nil, err
	}

	resp, err := http.Post(url, "application/json", bytes.NewBuffer(jsonBody))
	if err != nil {
		fmt.Println("fail to request ...........")
		return nil, err
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("fail to read response  ...........")
		return nil, err
	}

	var approvalResp GetApprovalResponse
	err = json.Unmarshal(body, &approvalResp)
	if err != nil {
		fmt.Println("fail to unmarshal response ...........")

		return nil, err
	}

	if approvalResp.Errcode != 0 {
		return nil, fmt.Errorf("Error: %s", approvalResp.Errmsg)
	}

	return &approvalResp, nil
}

func OnEventReceived(_ context.Context, df *payload.DataFrame) (*payload.DataFrameResponse, error) {
	eventHeader := event.NewEventHeaderFromDataFrame(df)

	if eventHeader.EventType == "bpms_instance_change" {

		var record map[string]any

		err := json.Unmarshal([]byte(df.Data), &record)

		if err != nil {
			panic(err)
		}
		/**
				fmt.Println("processInstanceId", record["processInstanceId"])
				fmt.Println("businessId", record["businessId"])
				fmt.Println("type", record["type"])
		**/
		if record["result"] == "agree" {
			fmt.Println("it is approved!")
		}

		token, err := getAccessToken(clientId, clientSecret)

		if err != nil {
			log.Fatalf("Error getting access token: %v", err)
		}

		// Step 2: 获取审批单内容
		approvalDetails, err := getApprovalDetails(token, record["processInstanceId"].(string))
		if err != nil {
			log.Fatalf("Error getting approval details: %v", err)
		}

		// 输出审批单内容
		//	fmt.Printf("Approval Data: %s\n", approvalDetails.ProcessInstance)
		instance, _ := json.Marshal(approvalDetails.ProcessInstance)

		var instanceDetails map[string]any

		json.Unmarshal(instance, &instanceDetails)

		fmt.Println("!!!!!!!!!!!!!")
		fmt.Println(instanceDetails["form_component_values"])
		fmt.Println("!!!!!!!!!!!!!")
		fields := instanceDetails["form_component_values"].([]any)

		for _, f := range fields {
			x := f.(map[string]any)
			fmt.Println(x["name"], ":", x["value"])
		}

		fmt.Println(instanceDetails["status"])
		fmt.Println("-----------------")
		//	fmt.Println(df.Data)
	}
	/**
	logger.GetLogger().Infof("received event, delay=%s, eventType=%s, eventId=%s, eventBornTime=%d, eventCorpId=%s, eventUnifiedAppId=%s, data=%s",
		time.Duration(time.Now().UnixMilli()-eventHeader.EventBornTime)*time.Millisecond,
		eventHeader.EventType,
		eventHeader.EventId,
		eventHeader.EventBornTime,
		eventHeader.EventCorpId,
		eventHeader.EventUnifiedAppId,
		df.Data)


	*/
	// put your code here; 可以在这里添加你的业务代码，处理事件订阅的业务逻辑；

	return event.NewSuccessResponse()
}

func main() {

	logger.SetLogger(logger.NewStdTestLogger())
	cli := client.NewStreamClient(client.WithAppCredential(client.NewAppCredentialConfig(clientId, clientSecret)))

	cli.RegisterAllEventRouter(OnEventReceived)

	err := cli.Start(context.Background())
	if err != nil {
		panic(err)
	}

	defer cli.Close()

	select {}

}
