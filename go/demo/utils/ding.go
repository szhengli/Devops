package utils


import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
)

const urls = "https://oapi.dingtalk.com/robot/send?access_token=e6705efada8ae39dbb260357aae2642c5b03741be11a1d9a7a6071682018c9bc"

func SendDing(msg string) bool {
	content, data := make(map[string] string), make(map[string] interface{})
	content["content"] = msg
	data["msgtype"] = "text"
	data["text"] = content

	payload, _ := json.Marshal(data)

	res, err := http.Post(urls,"application/json", bytes.NewReader(payload))
	if err != nil{
		fmt.Println(err)
		return false
	}
	defer res.Body.Close()
	body, _ := ioutil.ReadAll(res.Body)
	fmt.Println(string(body))
	return true
}

