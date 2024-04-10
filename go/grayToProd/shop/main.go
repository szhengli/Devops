package main

import (
	"go-micro.dev/v4"
	"go-micro.dev/v4/logger"
	"shop/config"
	"shop/handler"
	pb "shop/proto"

	grpcc "github.com/go-micro/plugins/v4/client/grpc"
	grpcs "github.com/go-micro/plugins/v4/server/grpc"
)

var (
	service = "shop"
	version = "latest"
)

func main() {

	config.Load()

	// Create service
	srv := micro.NewService(
		micro.Server(grpcs.NewServer()),
		micro.Client(grpcc.NewClient()),
		micro.Address(config.Address()),
	)
	srv.Init(
		micro.Name(service),
		micro.Version(version),
	)

	// Register handler
	cfg := config.Get()
	shopService := &handler.Shop{
		Hello: pb.NewHelloworldService(cfg.Helloworld, srv.Client()),
	}
	if err := pb.RegisterShopHandler(srv.Server(), shopService); err != nil {
		logger.Fatal(err)
	}
	// Run service

	if err := srv.Run(); err != nil {
		logger.Fatal(err)
	}
}
