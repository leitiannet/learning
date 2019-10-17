package main

import (
	"context"
	"fmt"

	"google.golang.org/grpc"

	"rpcdemo/grpc/greeter"
)

const (
	address     = "localhost:9090"
	defaultName = "world"
)

func main() {
	conn, err := grpc.Dial(address, grpc.WithInsecure())
	if err != nil {
		fmt.Println(err)
		return
	}
	defer conn.Close()
	client := greeter.NewGreeterClient(conn)
	result, err := client.SayHello(context.Background(), &greeter.Request{Name: defaultName})
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(result.Message)
}
