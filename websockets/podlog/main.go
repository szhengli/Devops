package main

import (
	"fmt"
	"log"
	"net/http"
	"podlog/utilities"
)
var watcher= make(map[string] chan bool,1)

func handler(w http.ResponseWriter, r *http.Request) {
	podName := r.URL.Query()["podName"][0]
	namespace := r.URL.Query()["namespace"][0]
	randID := r.URL.Query()["randID"][0]
	watcher[podName + "_" + randID] = make(chan bool, 1)
	print("------------------------")
	print(podName)
	go utilities.Getlog(namespace, podName, randID, watcher)
	_, err := fmt.Fprintf(w, "Hi there, I love %s!", r.URL.Path[1:])
	if err != nil {
		return
	}
}



func exithandler(w http.ResponseWriter, r *http.Request) {
	podName := r.URL.Query()["podName"][0]
	namespace := r.URL.Query()["namespace"][0]
	randID := r.URL.Query()["randID"][0]
    if _, ok := watcher[podName + "_" + randID]; ok {
	  print("has \n")
		watcher[namespace + "_"+ podName + "_" + randID] <- true
		_, err := fmt.Fprintf(w, "exit  *************"+ namespace + "_"+ podName + "----"+ randID, r.URL.Path[1:])
		if err != nil {
			return
		}
	}else {
		print("not\n")
	}

}



func handlerDemo(w http.ResponseWriter, r *http.Request) {


}

func candelDemo(w http.ResponseWriter, r *http.Request) {

}

func main() {
	http.HandleFunc("/podlog", handler)
	http.HandleFunc("/exitpodlog", exithandler)
	http.HandleFunc("/demo", handlerDemo)
	http.HandleFunc("/cancel", candelDemo)
	log.Fatal(http.ListenAndServe(":8088", nil))

}
