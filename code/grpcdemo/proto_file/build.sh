#!/bin/bash
mkdir ../greeter
protoc -I. --go_out=plugins=grpc:../greeter ./greeter.proto