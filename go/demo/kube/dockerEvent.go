package kube

import (
	"context"
	"demo/utils"
	"fmt"
	"github.com/docker/docker/api/types"
	"github.com/docker/docker/client"
	"github.com/pkg/errors"
)



func MonitorEvents(ctx context.Context) {
	dc, err := client.NewClientWithOpts()
	if err !=nil {
		err := errors.Wrap(err, "while creating docker clients")
		if err != nil {
			return
		}
	}
	events, errs := dc.Events(ctx, types.EventsOptions{})

	for {
		select {
		case e := <- events:
			if e.Type == "container" {
				podName := e.Actor.Attributes["io.kubernetes.pod.name"]
				namespace := e.Actor.Attributes["io.kubernetes.pod.namespace"]
				dockerType := e.Actor.Attributes["io.kubernetes.docker.type"]
				if dockerType == "container" {
					switch e.Status {
					case "oom" :
						msg := "OOM error Alert [go]: " + "podName: " + namespace + "/" + podName
						utils.SendDing(msg)
					case "die" :
						fmt.Println(podName + "---- die ----")
					}
				}
			}
		case e := <-errs:
			fmt.Println(e.Error())
		}
	}


}
