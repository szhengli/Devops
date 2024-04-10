package main

import (
	grpcc "github.com/go-micro/plugins/v4/client/grpc"
	etcdCfg "github.com/go-micro/plugins/v4/config/source/etcd"
	grpcs "github.com/go-micro/plugins/v4/server/grpc"
	"go-micro.dev/v4"
	"go-micro.dev/v4/config"
	"go-micro.dev/v4/logger"
	"helloworld/globles"
	"helloworld/handler"
	pb "helloworld/proto"
)

var (
	service = "helloworld"
	version = "latest"
)


func main() {
	// Create service

	etcdSource := etcdCfg.NewSource(
		etcdCfg.WithAddress("192.168.2.89:2379"),
	)
	conf, _ := config.NewConfig()

	conf.Load(etcdSource)

	w, _ := conf.Watch("micro", "config")

	go func() {
		for {
			v, _ := w.Next()

			//fmt.Println("!!!!!!!!!!!!!!!")
			v.Scan(&globles.Ht)
			//fmt.Println(string(v.Bytes()))
			//fmt.Println(v.StringMap())
			//fmt.Println("!!!!!!!!!!!!!!!")
		}
	}()

	srv := micro.NewService(
		micro.Server(grpcs.NewServer()),
		micro.Client(grpcc.NewClient()),
		micro.Config(conf),
	)

	srv.Init(
		micro.Name(service),
		micro.Version(version),
	)

	// Register handler
	if err := pb.RegisterHelloworldHandler(srv.Server(), new(handler.Helloworld)); err != nil {
		logger.Fatal(err)
	}
	// Run service

	if err := srv.Run(); err != nil {
		logger.Fatal(err)
	}
}
