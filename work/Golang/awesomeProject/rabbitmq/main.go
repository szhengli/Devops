package rabbitmq

import (
	"context"
	amqp "github.com/rabbitmq/amqp091-go"
	"log"
	"strconv"
	"time"
)

func failOnError(err error, msg string) {
	if err != nil {
		log.Panicf("%s: %s", msg, err)
	}
}

func Send() {
	conn, err := amqp.Dial("amqp://guest:guest@192.168.2.207:5672/")
	failOnError(err, "Failed to connect to RabbitMQ")
	defer conn.Close()
	ch, err := conn.Channel()
	failOnError(err, "Failed to open a channel")
	defer conn.Close()

	err = ch.ExchangeDeclare(
		"logs.topic",
		"topic",
		true,
		false,
		false,
		false,
		nil,
	)
	failOnError(err, "Failed to declare an exchange")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	body := "Hello World!"
	n := 0
	for {
		n++
		err = ch.PublishWithContext(ctx, "logs.topic", "status.suzhou.good", false, false, amqp.Publishing{
			DeliveryMode: amqp.Persistent,
			ContentType:  "text/plain",
			Body:         []byte(body + strconv.FormatInt(int64(n), 10))})
		failOnError(err, "Failed to publish a message")
		log.Printf(" [x] Sent %s\n", body+strconv.FormatInt(int64(n), 10))

		time.Sleep(2 * time.Second)

	}

}

func Receive() {
	conn, err := amqp.Dial("amqp://guest:guest@192.168.2.207:5672/")
	failOnError(err, "Failed to connect to RabbitMQ")
	defer conn.Close()
	ch, err := conn.Channel()
	err = ch.ExchangeDeclare(
		"logs.topic",
		"topic",
		true,
		false,
		false,
		false,
		nil,
	)
	failOnError(err, "Failed to declare an exchange")

	q, err := ch.QueueDeclare(
		"",    // name
		false, // durable
		false, // delete when unused
		true,  // exclusive
		false, // no-wait
		nil,   // arguments
	)

	//err = ch.Qos(1, 0, false)

	//	q, err := ch.QueueDeclare("hello", false, false, false, false, nil)
	failOnError(err, "Failed to declare a queue")

	err = ch.QueueBind(q.Name, "status.suzhou.*", "logs.topic", false, nil)

	failOnError(err, "Failed to bind a queue")
	msgs, err := ch.Consume(
		q.Name, // queue
		"",     // consumer
		true,   // auto ack
		false,  // exclusive
		false,  // no local
		false,  // no wait
		nil,    // args
	)
	failOnError(err, "Failed to register a consumer")
	//var forever chan struct{}

	//go func() {
	for d := range msgs {
		deal(&d)
	}
	//}()
	//<-forever
}

func deal(d *amqp.Delivery) {
	msg := string(d.Body)
	log.Println("beging to process  " + msg)
	time.Sleep(4 * time.Second)
	//	err := d.Ack(false)
	//failOnError(err, "Failed to ack the msg")
	log.Println("has processed " + msg + "!!!!!!!!!!!!")
}
