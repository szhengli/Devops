package main

import (
	"context"
	"fmt"
	mq "github.com/go-micro/plugins/v4/broker/rabbitmq"
	"github.com/go-micro/plugins/v4/registry/etcd"
	"go-micro.dev/v4"
	"go-micro.dev/v4/broker"
	registry "go-micro.dev/v4/registry"
	"log"
	"time"
)

var (
	topic        = "go.micro.topic.foo"
	edcdRegistry = etcd.NewRegistry(registry.Addrs("192.168.2.89:2379"))
	mqbroker     = mq.NewBroker(broker.Addrs("amqp://guest:guest@192.168.2.207:5672/"),
		mq.ExchangeName("user_exchange"),
		mq.DurableExchange(),
	)
	service = micro.NewService(
		micro.Name("helloworld"),
		micro.Handle(new(Helloworld)),
		micro.Address(":8080"),
		micro.Registry(edcdRegistry),
	)
)

func pub() {
	tick := time.NewTicker(time.Second)
	i := 0

	for _ = range tick.C {
		event := micro.NewEvent(topic, service.Client())

		msg := &broker.Message{
			Header: map[string]string{
				"id": fmt.Sprintf("%d", i),
			},
			Body: []byte(fmt.Sprintf("%d: %s", i, time.Now().String())),
		}
		if err := event.Publish(context.TODO(), msg); err != nil {
			log.Printf("[pub] failed: %v", err)
		} else {
			fmt.Println("[pub] pubbed message:", string(msg.Body))
		}
		i++
	}
}

func sub() {

	_, err := broker.Subscribe(topic, func(p broker.Event) error {
		fmt.Println("[sub] received message:", string(p.Message().Body), "header", p.Message().Header)
		return nil
	})
	if err != nil {
		fmt.Println(err)
	}
}

type Request struct {
	Name string `json:"name"`
}

type Response struct {
	Message string `json:"message"`
}

type Helloworld struct{}

func (h *Helloworld) Greeting(ctx context.Context, req *Request, rsp *Response) error {
	rsp.Message = "Hello " + req.Name

	go pub()
	go sub()
	time.Sleep(1 * time.Minute)
	return nil
}

func main() {

	service.Init(micro.Broker(mqbroker))

	service.Run()

}
