package handler

import (
	"context"
	"go-micro.dev/v4/logger"

	pb "shop/proto"
)

type Shop struct {
	Hello pb.HelloworldService
}

func (e *Shop) Buy(ctx context.Context, req *pb.BuyRequest, rsp *pb.BuyResponse) error {
	logger.Infof("Received Shop.Call request: %v", req)
	hel, err := e.Hello.Echo(ctx, &pb.Request{
		Name: req.Name,
	})

	if err != nil {
		panic(err)
	}
	rsp.Msg = "Buy    " + hel.Msg
	return nil
}
