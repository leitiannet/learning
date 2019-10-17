package main

import (
	"fmt"

	"git.apache.org/thrift.git/lib/go/thrift"

	greeter "rpcdemo/thrift/greeter2"
)

const (
	address     = "localhost:9092"
	defaultName = "world"
)

func main() {
	transportFactory := thrift.NewTBufferedTransportFactory(8192)
	protocolFactory := thrift.NewTBinaryProtocolFactoryDefault()
	transport, err := thrift.NewTSocket(address)
	if err != nil {
		fmt.Println(err)
		return
	}
	useTransport := transportFactory.GetTransport(transport)
	defer transport.Close()

	if err := transport.Open(); err != nil {
		fmt.Println(err)
		return
	}
	mp := thrift.NewTMultiplexedProtocol(protocolFactory.GetProtocol(useTransport), "processor1")
	client := greeter.NewGreeterClientProtocol(useTransport, mp, mp)
	txt, err := client.SayHello(defaultName)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(txt)

	mp2 := thrift.NewTMultiplexedProtocol(protocolFactory.GetProtocol(useTransport), "processor2")
	client2 := greeter.NewGreeter2ClientProtocol(useTransport, mp2, mp2)
	txt, err = client2.SayHello2(defaultName)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(txt)
}
