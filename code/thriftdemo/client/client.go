package main

import (
	"fmt"

	"git.apache.org/thrift.git/lib/go/thrift"

	"thriftdemo/greeter"
)

const (
	address     = "localhost:9090"
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
	client := greeter.NewGreeterClientFactory(useTransport, protocolFactory)
	txt, err := client.SayHello(defaultName)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(txt)
}
