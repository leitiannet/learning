/*
 * Copyright (c) 2021 yedf. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */

package dtmimp

const (
	// ResultFailure for result of a trans/trans branch
	ResultFailure = "FAILURE"
	// ResultSuccess for result of a trans/trans branch
	ResultSuccess = "SUCCESS"
	// ResultOngoing for result of a trans/trans branch
	ResultOngoing = "ONGOING"
	// DBTypeMysql const for driver mysql
	DBTypeMysql = "mysql"
	// DBTypePostgres const for driver postgres
	DBTypePostgres = "postgres"
	// DBTypeRedis const for driver redis
	DBTypeRedis = "redis"
	// Jrpc const for json-rpc
	Jrpc = "json-rpc"
	// JrpcCodeFailure const for json-rpc failure
	JrpcCodeFailure = -32901

	// JrpcCodeOngoing const for json-rpc ongoing
	JrpcCodeOngoing = -32902

	// MsgDoBranch0 const for DoAndSubmit barrier branch
	MsgDoBranch0 = "00"
	// MsgDoBarrier1 const for DoAndSubmit barrier barrierID
	MsgDoBarrier1 = "01"
	// MsgDoOp const for DoAndSubmit barrier op
	MsgDoOp = "msg"
)
