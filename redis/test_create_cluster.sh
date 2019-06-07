#!/bin/bash

<<EOF
######这里是说明######
功能描述: 创建单机redis集群
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

# bash -x test_create_cluster.sh
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
└── redis-start.sh

3 directories, 25 files
EOF

#配置
REDISDIR="/usr/local/redis-3.0.4/bin"
CLUSTERDIR="/usr/local/cluster"
PORT=7000
NODES=6
REPLICAS=1

#通过config.sh修改默认配置
if [ -a config.sh ]
then
    source "config.sh"
fi

#根据PORT和NODES计算ENDPORT
ENDPORT=$((PORT+NODES-1))
#存放节点配置、数据和日志的目录
CONFDIR="${CLUSTERDIR}/conf"
DATADIR="${CLUSTERDIR}/data"
LOGDIR="${CLUSTERDIR}/log"
RUNFILE="${CLUSTERDIR}/redis-start.sh"

#停止所有redis节点
#ps -ef | grep redis | grep cluster | awk '{print $2}' | xargs kill -9
i=${PORT}
while ((i <= ENDPORT))
do
	${REDISDIR}/redis-cli -p ${i} shutdown nosave
	i=$((i+1))
done

#删除相关文件夹和文件
rm -rf ${CONFDIR} ${DATADIR} ${LOGDIR} ${RUNFILE}
#创建相关文件夹和文件
mkdir ${CONFDIR}
mkdir ${DATADIR}
mkdir ${LOGDIR}
touch ${RUNFILE}
echo '#!/bin/sh' >> ${RUNFILE}

#集群的节点列表
HOSTS=""
i=$PORT
while ((i <= ENDPORT))
do
	#1,拼接节点列表
	HOSTS="$HOSTS 127.0.0.1:${i}"
	#2,生成redis配置文件
	cat <<EOF > ${CONFDIR}/redis-${i}.conf
#节点端口
port ${i}
#开启集群模式
cluster-enabled yes
#节点超时时间，单位毫秒
cluster-node-timeout 5000
#集群内部配置文件
cluster-config-file ${DATADIR}/nodes-${i}.conf
dir ${DATADIR}
#快照名称
dbfilename dump-${i}.rdb
appendonly no
#appendfilename "appendonly-${i}.aof"
save "" 
# save 900 1 
# save 300 10 
# save 60 10000
#日志文件
logfile ${LOGDIR}/redis-${i}.log
#日志级别: debug, verbose, notice, warning
loglevel verbose
#后台运行
daemonize yes
EOF
	#3,追加启动命令
	echo "${REDISDIR}/redis-server ${CONFDIR}/redis-${i}.conf &" >> ${RUNFILE}
	
	i=$((i+1))
done

#启动所有redis节点
chmod a+x ${RUNFILE}
bash ${RUNFILE}

#创建redis集群
${REDISDIR}/redis-trib.rb create --replicas ${REPLICAS} ${HOSTS}