/*
 * Copyright (c) 2021 yedf. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 */

package dtmsvr

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestUtils(t *testing.T) {
	CronExpiredTrans(1)
	sleepCronTime()
}

func TestSetNextCron(t *testing.T) {
	conf.RetryInterval = 10
	tg := TransGlobal{}
	tg.NextCronInterval = conf.RetryInterval
	tg.RetryInterval = 15
	assert.Equal(t, int64(15), tg.getNextCronInterval(cronReset))
	tg.RetryInterval = 0
	assert.Equal(t, conf.RetryInterval, tg.getNextCronInterval(cronReset))
	assert.Equal(t, conf.RetryInterval*2, tg.getNextCronInterval(cronBackoff))
	tg.TimeoutToFail = 3
	assert.Equal(t, int64(3), tg.getNextCronInterval(cronReset))
}
