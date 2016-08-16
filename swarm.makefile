
SWARM_PORT=4000
SWARM_OPT=-H tcp://${HEADHOST}:${SWARM_PORT}
SWARM_IMAGE=swarm:1.2.3
CLUSTER_SWARM=etc/_cluster_swarm.txt
ETCD=etcd-v2.2.5-linux-amd64

etcd-start: $(SRVDIR)
	[ -d $(SRVDIR)/$(ETCD) ] || ( curl -L  https://github.com/coreos/etcd/releases/download/v2.2.5/$(ETCD).tar.gz -o $(SRVDIR)/$(ETCD).tar.gz ; \
	    tar xzf $(SRVDIR)/$(ETCD).tar.gz -C $(SRVDIR) )
	cd $(SRVDIR)/$(ETCD) && \
		nohup ./etcd \
		-initial-advertise-peer-urls http://${HEADHOST}:2380 \
		-listen-peer-urls="http://0.0.0.0:2380,http://0.0.0.0:7001" \
		-listen-client-urls="http://0.0.0.0:2379,http://0.0.0.0:4001" \
		-advertise-client-urls="http://${HEADHOST}:2379" \
		-initial-cluster-token etcd-01 \
		-initial-cluster="default=http://${HEADHOST}:2380" \
		-initial-cluster-state new > etcd.log &
	sleep 1
	tail $(SRVDIR)/$(ETCD)/etcd.log

etcd-stop:
	pkill -9 etcd

etcd-check:
	curl -L -g http://${HEADHOST}:2379/v2/keys/?recursive=true | json_pp

${CLUSTER_SWARM}: ${CLUSTER_HOSTS}
	#	cat ${CLUSTER_HOSTS} | sed 's/$$/:2375/' > ${CLUSTER_SWARM}

swarm-check: etcd-check swarm-info
	@echo "OK"

_swarm-check-master-stopped:
	@if [[ `${DOCKER_CMD} ps | grep swarm`  ]] ; then echo "swarm master is already running" ; exit 1; fi

swarm-start-master: _swarm-check-master-stopped ${CLUSTER_SWARM}  ## start swarm master
	#	${DOCKER_CMD} run -v ${HERE}:/cfg -d -p ${SWARM_PORT}:2375 --name=swarm_master ${SWARM_IMAGE} manage --strategy random file:///cfg/${CLUSTER_SWARM}
	${DOCKER_CMD} run -d -p ${SWARM_PORT}:2375 --name=swarm_master ${SWARM_IMAGE} manage --strategy random etcd://${HEADHOST}:2379

swarm-stop-master: ## stop swarm master
	if ${DOCKER_CMD} ps -a | grep swarm_master ; then \
	${DOCKER_CMD} rm -f swarm_master ; \
	fi

swarm-logs:
	${DOCKER_CMD} logs swarm_master	

swarm-restart-master: swarm-stop-master swarm-start-master ## restart swarm master

swarm-stop: swarm-unregister-nodes swarm-stop-master etcd-stop
	@echo Stop OK

swarm-start: etcd-start swarm-start-master swarm-register-nodes
	@echo Start OK

swarm-restart: swarm-stop swarm-start
	@echo Restart OK

swarm-info: ## check swarm
	${DOCKER_CMD} ${SWARM_OPT} info

swarm-ps: ## list containers running in swarm
	${DOCKER_CMD} ${SWARM_OPT} ps

swarm-psa: ## list all containers in swarm
	${DOCKER_CMD} ${SWARM_OPT} ps -a

swarm-register-nodes:
	${PSSH} -h ${CLUSTER_HOSTS} -i 'MYIP=$$(host `hostname -f`| awk "{print \$$5}") ; docker run --name swarm_node -d ${SWARM_IMAGE} join --advertise=[$$MYIP]:2375 etcd://${HEADHOST}:2379'

swarm-unregister-nodes:
	${PSSH} -h ${CLUSTER_HOSTS} -i 'if docker ps -a|grep swarm_node ; then docker rm -f swarm_node ; fi'
