#!/bin/bash

<<EOF
######这里是说明######
功能描述: 操作单机redis集群
参考redis-3.0.4/utils/create-cluster
redis命令
/usr/local/redis-3.0.4/bin/redis-cli -p 7000 shutdown nosave
/usr/local/redis-3.0.4/bin/redis-server /usr/local/cluster/conf/redis-7000.conf &
/usr/local/redis-3.0.4/bin/redis-trib.rb create --replicas 1 127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 127.0.0.1:7006
/usr/local/redis-3.0.4/bin/redis-trib.rb check 127.0.0.1:7000
通过使用端口号区分不同节点，防止同一个机器下多个节点彼此覆盖
redis-{port}.conf
redis-port.log
nodes-{port}.conf
dump-{port}.rdb
appendonly-{port}.aof

# bash -x redis_cluster.sh create
# tree /usr/local/cluster
/usr/local/cluster
├── conf
│   ├── redis-7000.conf
│   ├── redis-7001.conf
│   ├── redis-7002.conf
│   ├── redis-7003.conf
│   ├── redis-7004.conf
│   └── redis-7005.conf
├── data
│   ├── dump-7000.rdb
│   ├── dump-7001.rdb
│   ├── dump-7002.rdb
│   ├── dump-7003.rdb
│   ├── dump-7004.rdb
│   ├── dump-7005.rdb
│   ├── nodes-7000.conf
│   ├── nodes-7001.conf
│   ├── nodes-7002.conf
│   ├── nodes-7003.conf
│   ├── nodes-7004.conf
│   └── nodes-7005.conf
├── log
│   ├── redis-7000.log
│   ├── redis-7001.log
│   ├── redis-7002.log
│   ├── redis-7003.log
│   ├── redis-7004.log
│   └── redis-7005.log
├── redis-start.sh
└── redis-stop.sh

3 directories, 26 files
EOF

#redis命令行工具
REDIS_DIR="/usr/local/redis-3.0.4/bin/"
REDIS_SERVER="${REDIS_DIR}redis-server"
REDIS_CLI="${REDIS_DIR}redis-cli"
REDIS_TRIB="${REDIS_DIR}redis-trib.rb"

#存放节点配置文件、数据和日志的目录
CLUSTER_DIR="/usr/local/cluster/"
CLUSTER_CONF_DIR="${CLUSTER_DIR}conf/"
CLUSTER_DATA_DIR="${CLUSTER_DIR}data/"
CLUSTER_LOG_DIR="${CLUSTER_DIR}log/"
#节点启动文件
CLUSTER_START_FILE="${CLUSTER_DIR}redis-start.sh"
CLUSTER_STOP_FILE="${CLUSTER_DIR}redis-stop.sh"
#命令行参数
COMMAND=""
PORT=7000
NODES=6

##############################辅助函数########################
#功能说明
function usage()
{
	echo "Usage: $0 [create|delete|start|stop|expand|shrink]			"
	echo "create <port> <nodes>     -- Create and launch a cluster.  	"
	echo "delete                    -- Stop and delete cluster.      	"
	echo "start                     -- Start Redis Cluster instances.	"
	echo "stop                      -- Stop Redis Cluster instances. 	"
	echo "expand <port> <nodes>     -- Add Redis Cluster instances.   	"
	echo "shrink <port> <nodes>     -- Remove Redis Cluster instances.	"
}

#创建redis集群相关文件夹和文件
function create_resource()
{
	mkdir ${CLUSTER_CONF_DIR}
	mkdir ${CLUSTER_DATA_DIR}
	mkdir ${CLUSTER_LOG_DIR}
	touch ${CLUSTER_START_FILE}
	touch ${CLUSTER_STOP_FILE}
	echo '#!/bin/sh' >> ${CLUSTER_START_FILE}
	echo '#!/bin/sh' >> ${CLUSTER_STOP_FILE}
	chmod a+x ${CLUSTER_START_FILE}
	chmod a+x ${CLUSTER_STOP_FILE}
	
}

#删除redis集群相关文件夹和文件
function remove_resource()
{
	# rm -rf ${CLUSTER_DIR}
	rm -rf ${CLUSTER_CONF_DIR} ${CLUSTER_DATA_DIR} ${CLUSTER_LOG_DIR}
	rm -rf ${CLUSTER_START_FILE} ${CLUSTER_STOP_FILE}
}

#增加redis节点
function add_node()
{
	for i in `seq ${PORT} $((PORT+NODES-1))`;
	do
		conf_file="${CLUSTER_CONF_DIR}redis-${i}.conf"
		cat <<EOF > ${conf_file}
#节点端口
port ${i}
#开启集群模式
cluster-enabled yes
#节点超时时间，单位毫秒
cluster-node-timeout 5000
#集群内部配置文件
cluster-config-file ${CLUSTER_DATA_DIR}nodes-${i}.conf
dir ${CLUSTER_DATA_DIR}
#快照名称
dbfilename dump-${i}.rdb
appendonly no
#appendfilename "appendonly-${i}.aof"
save "" 
# save 900 1 
# save 300 10 
# save 60 10000
#日志文件
logfile ${CLUSTER_LOG_DIR}redis-${i}.log
#日志级别: debug, verbose, notice, warning
loglevel verbose
#后台运行
daemonize yes
EOF
		#追加启动命令
		echo "${REDIS_SERVER} ${conf_file} &" >> ${CLUSTER_START_FILE}
		echo "${REDIS_CLI} -p ${i} shutdown nosave" >> ${CLUSTER_STOP_FILE}
	done
}

#删除redis节点
function del_node()
{
	for i in `seq ${PORT} $((PORT+NODES-1))`;
	do
		#删除端口对应的文件
		rm -rf ${CLUSTER_CONF_DIR}redis-${i}.conf
		rm -rf ${CLUSTER_DATA_DIR}dump-${i}.rdb
		rm -rf ${CLUSTER_DATA_DIR}nodes-${i}.conf
		rm -rf ${CLUSTER_LOG_DIR}redis-${i}.log
		#删除脚本中端口对应的行
		sed -i "/${i}/d" ${CLUSTER_START_FILE}
		sed -i "/${i}/d" ${CLUSTER_STOP_FILE}
	done
}

#启动所有redis节点
function start_node()
{
	if [ -f "${CLUSTER_START_FILE}" ]; then  
		bash ${CLUSTER_START_FILE}
	fi
}

#停止所有redis节点
function stop_node()
{
	if [ -f "${CLUSTER_STOP_FILE}" ]; then  
		bash ${CLUSTER_STOP_FILE}
	else
		#ps -ef | grep 'redis-server' | grep 'cluster' | awk '{print $2}' | xargs kill -9
		pids=`ps -ef | grep 'redis-server' | grep 'cluster' | awk '{print $2}'`
		for pid in ${pids};
		do
			if [ ! -z "${pid}" ]; then
				kill -9 ${pid}
			fi
		done
	fi
}

#启动redis集群
function launch_cluster()
{
	HOSTS=""
	#获取运行的redis端口
	ports=`ps -ef | grep 'redis-server' | grep 'cluster' | awk '{print $9}' | cut -f 2 -d ":" | sort`
	for i in ${ports};
	do
		if [ ! -z "${i}" ]; then
			HOSTS="$HOSTS 127.0.0.1:${i}"
		fi
	done
	if [ -z "${HOSTS}" ]; then
		echo "no redis cluster running"
		exit 1
	fi
	${REDIS_TRIB} create --replicas 1 ${HOSTS}
}

##############################执行入口########################
#通过config.sh修改默认配置
if [ -a config.sh ]
then
    source "config.sh"
fi

if [ $# -gt 0 ]; then
	COMMAND=$1
fi
if [ $# -gt 1 ]; then
	PORT=$2
fi
if [ $# -gt 2 ]; then
	NODES=$3
fi

if [ "${COMMAND}" == "create" ]
then
	stop_node
	remove_resource
	create_resource
	add_node
	start_node
	sleep 2
	launch_cluster
    exit 0
fi

if [ "${COMMAND}" == "delete" ]
then
	stop_node
	remove_resource
    exit 0
fi

if [ "${COMMAND}" == "start" ]
then
	start_node
    exit 0
fi

if [ "${COMMAND}" == "stop" ]
then
	stop_node
    exit 0
fi

if [ "${COMMAND}" == "expand" ]
then
	add_node
    exit 0
fi

if [ "${COMMAND}" == "shrink" ]
then
	del_node
    exit 0
fi

usage