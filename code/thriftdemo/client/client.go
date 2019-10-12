package main

import (
	"fmt"
	"os"

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
	var client [10]*greeter.GreeterClient
	for i := 0; i < 10; i++ {
		transport, err := thrift.NewTSocket(address)
		if err != nil {
			fmt.Fprintln(os.Stderr, "error resolving address:", err)
			os.Exit(1)
		}
		useTransport := transportFactory.GetTransport(transport)
		defer transport.Close()

		if err := transport.Open(); err != nil {
			fmt.Fprintln(os.Stderr, "error opening socket to localhost:9090", " ", err)
			os.Exit(1)
		}
		client[i] = greeter.NewGreeterClientFactory(useTransport, protocolFactory)
		name := fmt.Sprintf("%s-%d", defaultName, i)
		txt, err := client[i].SayHello(name)
		if err != nil {
			fmt.Fprintln(os.Stderr, "error operation", " ", err)
			os.Exit(1)
		}
		fmt.Println(txt)
	}
}
