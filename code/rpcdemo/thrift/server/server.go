package main

import (
	"fmt"

	"git.apache.org/thrift.git/lib/go/thrift"

	"rpcdemo/thrift/greeter"
)

const (
	address = "localhost:9091"
)

type GreeterHandler struct {
}

func (p *GreeterHandler) SayHello(name string) (r string, err error) {
	fmt.Println("get client info, name is:", name)
	return "Hello " + name, nil
}

func main() {
	var protocolFactory thrift.TProtocolFactory = thrift.NewTBinaryProtocolFactoryDefault()
	var transportFactory thrift.TTransportFactory = thrift.NewTBufferedTransportFactory(8192)
	transport, err := thrift.NewTServerSocket(address)
	if err != nil {
		fmt.Println(err)
		return
	}
	processor := greeter.NewGreeterProcessor(&GreeterHandler{})
	server := thrift.NewTSimpleServer4(processor, transport, transportFactory, protocolFactory)
	fmt.Printf("start server on %s...\n", address)
	if err := server.Serve(); err != nil {
		fmt.Println(err)
		return
	}
}
