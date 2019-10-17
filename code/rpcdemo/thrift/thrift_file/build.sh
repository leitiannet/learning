#!/bin/bash
thrift --gen go -out .. greeter.thrift
thrift --gen go -out .. greeter2.thrift