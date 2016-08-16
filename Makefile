# Makefile for building & starting everware-containers
# arguments can be supplied by -e:
#
#  IMAGE -- name of image to use
#

DOCKER_CMD=docker
DOCKER_CMD_NODE=sudo docker -H tcp://0.0.0.0:2375
PSSH=parallel-ssh -O StrictHostKeyChecking=no 
CLUSTER_HOSTS=etc/cluster.txt
IMAGE ?= yandex/rep:0.6.5
HERE:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
HEADHOST=head.haze.yandex.net
SRVDIR=srv


include swarm.makefile
include docker.makefile
include system.makefile
include bosun.makefile

help:
	@echo Usage: make [-e VARIABLE=VALUE] targets
	@echo "variables:"
	@grep -h "#\s\+\w\+ -- " $(MAKEFILE_LIST) |sed "s/#\s//"
	@echo
	@echo targets and corresponding dependencies:
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' -e 's/^/   /' | sed -e 's/##//'


$(SRVDIR): ## create srv for etcd & scollector
	[ -d $(SRVDIR) ] || mkdir -p $(SRVDIR)

uptime: ## uptime cluster
	${PSSH} -h ${CLUSTER_HOSTS} -i uptime

pull: ## pull image to cluster nodes
	${PSSH} -h ${CLUSTER_HOSTS} -i -t 0 ${DOCKER_CMD_NODE} pull ${IMAGE}

ps-user-containers: ${CLUSTER_HOSTS} ## list container running on the cluster
	${PSSH} -h ${CLUSTER_HOSTS} -i '${DOCKER_CMD_NODE} ps -a'

count-user-containers: ${CLUSTER_HOSTS} ## count container running on the cluster
	${PSSH} -h ${CLUSTER_HOSTS} -i '${DOCKER_CMD_NODE} ps | grep -v "CONTAINER ID" | wc -l'

images: ${CLUSTER_HOSTS} ## list images created at clusters
	${PSSH} -h ${CLUSTER_HOSTS} -i '${DOCKER_CMD_NODE} images'

rm-images: ${CLUSTER_HOSTS} ## remove all images
	${PSSH} -h ${CLUSTER_HOSTS} -i '${DOCKER_CMD_NODE} images -q | xargs ${DOCKER_CMD_NODE} rmi'

rm-user-containers: ${CLUSTER_HOSTS} ## stop & remove user containers
	${PSSH} -h ${CLUSTER_HOSTS} --timeout=0 -i '${DOCKER_CMD_NODE} ps -aq|xargs --no-run-if-empty ${DOCKER_CMD_NODE} rm -f'

df: ${CLUSTER_HOSTS} ## check disk free space on cluster nodes
	${PSSH} -h ${CLUSTER_HOSTS} -i df -h /

mdu: ## mfs du
	du -m --max-depth 1 /mnt/shared
