namespace go greeter2

service Greeter {
	string sayHello(1:string name);
}

service Greeter2 {
	string sayHello2(1:string name);
}