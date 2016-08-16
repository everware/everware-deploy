
DOCKER_OPTS = --ipv6 -H tcp://[::]:2375 -H unix:///var/run/docker.sock --fixed-cidr-v6=fc00::/64
DOCKER_CONFIG = /etc/default/docker
DOCKER_VERSION = 1.11.2-0~trusty

install_docker: pdocker-repo pdocker-install pdocker-version

pdocker-repo: ${CLUSTER_HOSTS}
	${PSSH} -h ${CLUSTER_HOSTS} -i 'echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" | sudo tee /etc/apt/sources.list.d/docker.list; cat /etc/apt/sources.list.d/docker.list'
	${PSSH} -h ${CLUSTER_HOSTS} 'sudo apt-get update'

pdocker-install: ${CLUSTER_HOSTS}
	${PSSH} -h ${CLUSTER_HOSTS} -i 'sudo apt-get install -y --force-yes docker-engine=${DOCKER_VERSION}'

pdocker-version: ${CLUSTER_HOSTS}
	${PSSH} -h ${CLUSTER_HOSTS} -i "${DOCKER_CMD_NODE} version"

pdocker-config: ${CLUSTER_HOSTS}
	${PSSH} -h ${CLUSTER_HOSTS} -i "sudo sed -i '/^DOCKER_OPTS/d' ${DOCKER_CONFIG} ; echo DOCKER_OPTS=\'${DOCKER_OPTS}\' | sudo tee -a ${DOCKER_CONFIG}"

pdocker-restart: ${CLUSTER_HOSTS}
	${PSSH} -h ${CLUSTER_HOSTS} -i "sudo service docker restart"

pdocker-stop: ## stop dockers on cluster
	${PSSH} -h ${CLUSTER_HOSTS} -i "sudo service docker stop"

pdocker-start: ## start dockers on cluster
	${PSSH} -h ${CLUSTER_HOSTS} -i "sudo service docker start"

pdocker-remove: ## remove docker directories
	${PSSH} -h ${CLUSTER_HOSTS} -i sudo rm -rf /var/lib/docker

pdocker-check: ${CLUSTER_HOSTS} ## check docker version
	${PSSH} -h ${CLUSTER_HOSTS} -i "dpkg -l | grep docker && ps ax|grep 'docker daemon'|grep -v grep"

pdocker-clean-key: ${CLUSTER_HOSTS} ## remove docker key (should be different for different nodes, otherwise swarm doesn't fly)
	${PSSH} -h ${CLUSTER_HOSTS} -i 'sudo rm -f /etc/docker/key.json && sudo service docker restart'


