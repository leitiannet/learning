package main

import (
	"fmt"

	"git.apache.org/thrift.git/lib/go/thrift"

	greeter "rpcdemo/thrift/greeter2"
)

const (
	address = "localhost:9092"
)

type GreeterHandler struct {
}

func (p *GreeterHandler) SayHello(name string) (r string, err error) {
	fmt.Println("get client info 1, name is:", name)
	return "Hello 1 " + name, nil
}

type Greeter2Handler struct {
}

func (p *Greeter2Handler) SayHello2(name string) (r string, err error) {
	fmt.Println("get client info 2, name is:", name)
	return "Hello 2 " + name, nil
}

func main() {
	var protocolFactory thrift.TProtocolFactory = thrift.NewTBinaryProtocolFactoryDefault()
	var transportFactory thrift.TTransportFactory = thrift.NewTBufferedTransportFactory(8192)
	transport, err := thrift.NewTServerSocket(address)
	if err != nil {
		fmt.Println(err)
		return
	}

	processor1 := greeter.NewGreeterProcessor(&GreeterHandler{})
	processor2 := greeter.NewGreeter2Processor(&Greeter2Handler{})
	var processor = thrift.NewTMultiplexedProcessor()
	processor.RegisterProcessor("processor1", processor1)
	processor.RegisterProcessor("processor2", processor2)
	server := thrift.NewTSimpleServer4(processor, transport, transportFactory, protocolFactory)
	fmt.Printf("start server on %s...\n", address)
	if err := server.Serve(); err != nil {
		fmt.Println(err)
		return
	}
}
