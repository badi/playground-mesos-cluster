#!/usr/bin/env sh

set -e

echo "STARING ZOOKEEPER"
docker run -d --name zk jplock/zookeeper:3.4.6
ZK_IP_ADDR=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" zk)

NMASTERS=3
QUORUM=2
echo "STARTING MASTERS"
for i in `seq $NMASTERS`; do
    name=mesos-master-$i
    docker run -d --name $name --link zk:zk -e MESOS_LOG_DIR=/master/log -e MESOS_ZK=zk://$ZK_IP_ADDR:2181/mesos -e MESOS_WORK_DIR=/master/work -e MESOS_QUORUM=$QUORUM redjack/mesos-master
done

NWORKERS=10
CPU=0.1
echo "STARTING WORKER"
for i in `seq $NWORKERS`; do
    name=mesos-worker-$i
    docker run -d --name $name --link zk:zk -e MESOS_MASTER=zk://$ZK_IP_ADDR:2181/mesos -e MESOS_RESOURCES=cpus:$CPU redjack/mesos-slave
done


echo "STARTING SHELL"
$SHELL

IMAGES="zk $(eval echo mesos-master-{`seq -s, $NMASTERS | sed 's/,$//'`}) $(eval echo mesos-worker-{`seq -s, $NWORKERS | sed 's/,$//'`})"
echo "KILLING IMAGES"
docker kill $IMAGES
echo "DELETEING IMAGES"
docker rm   $IMAGES
