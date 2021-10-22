package utilities

import (
	"bufio"
	"context"
	"fmt"
	"github.com/gorilla/websocket"
	v1 "k8s.io/api/core/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
	"math/rand"
	"time"
)

func Demo()  {
	for {
		time.Sleep(1)
		print("llll")
	}
}

func  getRandomString(l int) string {
	str := "0123456789abcdefghijklmnopqrstuvwxyz"
	bytes := []byte(str)
	result := []byte{}
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	for i := 0; i < l; i++ {
		result = append(result, bytes[r.Intn(len(bytes))])
	}
	return string(result)
}

func connect() *kubernetes.Clientset {
	// use the current context in kubeconfig
	config, err := clientcmd.BuildConfigFromFlags("", "/root/.kube/config")
	if err != nil {
		panic(err.Error())
	}
//	config, err :=clientcmd.BuildConfigFromKubeconfigGetter()
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err.Error())
	}
	return clientset
}

func clean()  {
	err := recover()
	if err != nil {
		fmt.Println(err)
		fmt.Println("something wrong!!!!!!!!!!!!!\n")
	}else {
		fmt.Println("session ends normally ###########\n")
	}

}

func Getlog(namespace string ,podName string, randID string, watcher map[string] chan bool)  {
	//defer clean()
	clientset := connect()

	req := clientset.CoreV1().Pods(namespace).GetLogs(podName,
		&v1.PodLogOptions{Follow: true})
	print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n")
	podLogs, err := req.Stream(context.TODO())
	print("^^^^^^^^^^^^^^^^^^^^^------------------^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n")
	if err != nil {
		fmt.Println(err)
		print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n")
		return
	}
	defer  podLogs.Close()
	r := bufio.NewReader(podLogs)
	print("^^^^^^^^^^^^^^^^^^^^^----------------111111111111111111--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n")
	const char = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

	c, _, err := websocket.DefaultDialer.Dial("ws://192.168.2.221:5678/" + namespace + "_" + podName + "_" + randID + "_" + getRandomString(4), nil)

	stop := false
	sid := podName + "_" + randID
	for {
		select {
			case <-watcher[sid]:
				print("/////////////////"+"stop"+ "////////////////////////////\n")
				stop = true
			default:
				print("*  \n")
				bytes, err := r.ReadBytes('\n')
				fmt.Println(string(bytes))
				print("***********************------------************************\n")
				err = c.WriteMessage(websocket.TextMessage, bytes)
				if err != nil {
					return
				}
			}
		if stop {
			print("quit.##############################################" + podName + "----"+ randID+ "\n")
			break
		}else {
			print("-------------------- next loop --------------------------------------- \n")
		}
	}


}