package main

import (
	"context"
	"fmt"
	"net"

	"google.golang.org/grpc"

	"rpcdemo/grpc/greeter"
)

const (
	address = "localhost:9090"
)

type GreeterHandler struct{}

func (g *GreeterHandler) SayHello(ctx context.Context, request *greeter.Request) (*greeter.Response, error) {
	fmt.Println("get client info, name is:", request.Name)
	response_msg := "Hello " + request.Name
	return &greeter.Response{Message: response_msg}, nil
}

func main() {
	conn, err := net.Listen("tcp", address)
	if err != nil {
		fmt.Println(err)
		return
	}
	defer conn.Close()
	server := grpc.NewServer()
	greeter.RegisterGreeterServer(server, &GreeterHandler{})
	fmt.Printf("start server on %s...\n", address)
	if err := server.Serve(conn); err != nil {
		fmt.Println(err)
		return
	}
}
