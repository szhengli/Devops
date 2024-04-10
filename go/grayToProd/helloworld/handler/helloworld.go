package handler

import (
	"context"
	"github.com/go-acme/lego/v4/log"
	"go-micro.dev/v4/logger"
	"helloworld/globles"
	pb "helloworld/proto"
)

type Helloworld struct{}

func (e *Helloworld) Call(ctx context.Context, req *pb.Request, rsp *pb.Response) error {
	logger.Infof("Received Helloworld.Call request: %v", req)
	log.Println("!!!!!!!!!!!!!!!!!!!!!")
	log.Println(globles.Ht.Address)
	log.Println("!!!!!!!!!!!!!!!!!!!!!")
	rsp.Msg = "Hello " + req.Name
	return nil
}

func (e *Helloworld) Echo(ctx context.Context, req *pb.Request, rsp *pb.Response) error {
	logger.Infof("Received Helloworld.Clean request: %v", req)


	rsp.Msg = "Hello " + req.Name
	return nil
}
