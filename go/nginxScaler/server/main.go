package main

import (
	"context"
	"fmt"
	"google.golang.org/grpc"
	"log"
	"math/rand"
	"net"
	pb "nginxScaler/externalscaler"
	"strconv"
	"time"
)

type Result struct {
	Size int `json:"size"`

}

type ExternalScaler struct {
	pb.UnimplementedExternalScalerServer
}

func (e *ExternalScaler)IsActive(ctx context.Context, scaledObject *pb.ScaledObjectRef)(*pb.IsActiveResponse, error)  {
	fmt.Println("receiveing isActive --------------- \n")
	/**
	res, err := http.Get("http://192.168.2.89:8080/metrics")
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}
	defer res.Body.Close()
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}

	payload := Result{}
	err = json.Unmarshal(body,&payload)
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}

	 */
	return &pb.IsActiveResponse{Result: true}, nil
}

func (e *ExternalScaler) GetMetricSpec(ctx context.Context, sor *pb.ScaledObjectRef) (*pb.GetMetricSpecResponse, error) {
	fmt.Println("receiveing GetMetricSpec --------------- \n")
	metricName:=sor.ScalerMetadata["metricName"]
	targetSize,_ :=  strconv.Atoi(sor.ScalerMetadata["targetSize"])
	return &pb.GetMetricSpecResponse{
		MetricSpecs: []*pb.MetricSpec{{
			MetricName: metricName,
			TargetSize: int64(targetSize),
		}},
	}, nil
}

func (e *ExternalScaler) StreamIsActive(scaledObject *pb.ScaledObjectRef, epsServer pb.ExternalScaler_StreamIsActiveServer) error {
	fmt.Println("receiveing StreamIsActive --------------- \n")
	for {
		select {
		case <-epsServer.Context().Done():
			// call cancelled
			return nil
		case <-time.Tick(time.Second * 4):
				size  := rand.Intn(20)
				fmt.Printf("size is  %d  ****************\n", size)
				epsServer.Send(&pb.IsActiveResponse{
					Result: size >4,
				})
			}
		}
}

func (e *ExternalScaler) GetMetrics(_ context.Context, metricRequest *pb.GetMetricsRequest) (*pb.GetMetricsResponse, error) {
	fmt.Println("receiveing GetMetrics --------------- \n")
	//size := rand.Intn(20)
	size :=100
	fmt.Printf("size is  %d  ^^^^^^^^^^^^^^^\n", size)
	return &pb.GetMetricsResponse{
		MetricValues: []*pb.MetricValue{{
			MetricName: "size",
			MetricValue: int64(size),
		}},
	}, nil
}

func main() {
	grpcServer := grpc.NewServer()
	lis, _ := net.Listen("tcp", ":6000")
	pb.RegisterExternalScalerServer(grpcServer, &ExternalScaler{})

	fmt.Println("listenting on :6000")
	if err := grpcServer.Serve(lis); err != nil {
		log.Fatal(err)
	}
}