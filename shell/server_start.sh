#! /bin/bash

#通过pid文件获取进程号，由应用程序操作pid文件
SERVER_NAME="xxxserver"
SERVER_EXEC="/sbin/xxxserver"
PID_FILE="/var/run/xxxserver.pid"
pid=0
error_msg=""
exec_opts=""

function exec_start()
{
	${SERVER_EXEC} ${exec_opts}
}

function exec_stop()
{
	#ps -eo 'pid,args' | grep ${SERVER_EXEC} | grep -v grep | awk '{print $1}' | xargs kill >/dev/null 2>&1
	kill -s SIGTERM ${pid} >/dev/null 2>&1
}

function ok_msg() 
{
    echo -e "[  OK      ]${1}"
}

function failed_msg() 
{
    echo -e "[  Err     ]${1}"
}

#set pid and error_msg
function load_process() 
{
	if [ ! -f "${PID_FILE}" ]; then error_msg="file ${PID_FILE} does not exists"; return 1; fi
    pid=`cat ${PID_FILE} 2>/dev/null`
	if [ ${pid} -lt 10 ]; then error_msg="pid ${pid} invalid"; return 2; fi
    ps -p ${pid} >/dev/null 2>&1; ret=$?
	if [ ${ret} -ne 0 ]; then error_msg="process ${pid} does not exists"; return 3; fi
    return 0;
}

function start() 
{
    load_process; ret=$? 
	if [ ${ret} -eq 0 ]; then failed_msg "${SERVER_NAME}(${pid}) is running, should not start it again"; return 1; fi
    ok_msg "start ${SERVER_NAME}..."
	exec_start
	for((i=0;i<5;i++)); do
		load_process; ret=$?
		if [ ${ret} -eq 0 ]; then 
			ok_msg "start ${SERVER_NAME}(${pid}) success"
			return 0
		else
			ok_msg "waiting for ${SERVER_NAME} to start..."
			sleep 1
		fi
    done
    failed_msg "start ${SERVER_NAME} failed"
    return 2
}

function stop()
{
    load_process; ret=$?
    if [ ${ret} -ne 0 ]; then failed_msg "${SERVER_NAME} is not running"; return 1; fi
    ok_msg "stop ${SERVER_NAME}..."
	exec_stop
	for((i=0;i<10;i++)); do
		if [ -d /proc/${pid} ]; then 
			ok_msg "Waiting for ${SERVER_NAME} to stop..."
			sleep 1
		else
			ok_msg "stop ${SERVER_NAME}(${pid}) by SIGTERM"
			break
		fi
    done
	load_process; ret=$?
	if [ ${ret} -eq 0 ]; then
		kill -s SIGKILL ${pid} >/dev/null 2>&1; ret=$?
		if [ ${ret} -ne 0 ]; then failed_msg "send signal SIGKILL failed ret=$ret"; return 2; fi
		ok_msg "stop ${SERVER_NAME}(${pid}) by SIGKILL"
	fi
	#app don't remove when kill by SIGKILL
	test -f ${PID_FILE} && rm ${PID_FILE}
	return 0
}

function status() 
{
    load_process; ret=$? 
	if [ ${ret} -eq 0 ]; then 
		ok_msg "${SERVER_NAME}(${pid}) is running."
	else
		ok_msg "${SERVER_NAME} is not running, $error_msg"; 
	fi
    
    return 0
}

cmd=$1
case "${cmd}" in
 start)
   start
   ;;
 stop)
   stop
   ;;
 restart)
   stop
   start
   ;;
 status)
   status
   ;;
 *)
   echo "Usage $0 [start|stop|restart|status]"
   ;;
esac
