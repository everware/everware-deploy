
BOSUN_IMAGE = stackexchange/bosun
SCOLLECTOR_SHARED = /mnt/shared/scollector


bosun-start: ## start monitoring (bosun)
	${DOCKER_CMD} run -d -p 4242:4242 -p 8070:8070 --name bosun ${BOSUN_IMAGE}

bosun-rm:
	docker rm -f bosun

bosun-stop:
	docker stop bosun

bosun-restart:
	docker restart bosun

bosun-exec:
	docker exec -ti bosun bash

bosun-update-conf:
	docker cp etc/bosun.conf bosun:/data/bosun.conf
	docker restart bosun

scollector-install: ${CLUSTER_HOSTS} ${SRVDIR}
	[ -f ${SRVDIR}/scollector-linux ] || ( \
		wget https://github.com/bosun-monitor/bosun/releases/download/0.5.0/scollector-linux-386 \
			-O ${SRVDIR}/scollector-linux ; \
		chmod +x ${SRVDIR}/scollector-linux ; \
		)
	sudo cp ${SRVDIR}/scollector-linux etc/scollector_supervisord.conf etc/scollector.toml ${SCOLLECTOR_SHARED}
	sudo cp -r scollector_metrics ${SCOLLECTOR_SHARED}
	sudo sed -i -e "s/#HEAD#/${HEADHOST}/" -e "s|#BASE#|${SCOLLECTOR_SHARED}|" \
		${SCOLLECTOR_SHARED}/scollector_supervisord.conf ${SCOLLECTOR_SHARED}/scollector.toml
	${PSSH} -h ${CLUSTER_HOSTS} -H ${HEADHOST} -i 'sudo cp ${SCOLLECTOR_SHARED}/scollector_supervisord.conf /etc/supervisor/conf.d; \
		sudo supervisorctl reload'

scollector-reload: ${CLUSTER_HOSTS}
	${PSSH} -h ${CLUSTER_HOSTS} -H ${HEADHOST} -i "sudo supervisorctl reload"

scollector-start: ${CLUSTER_HOSTS}
	${PSSH} -h ${CLUSTER_HOSTS} -H ${HEADHOST} -i "sudo supervisorctl start scollector"

scollector-check: ${CLUSTER_HOSTS}
	${PSSH} -h ${CLUSTER_HOSTS} -H ${HEADHOST} -i 'pgrep -f scollector-linux'

scollector-stop:
	${PSSH} -h ${CLUSTER_HOSTS} -H ${HEADHOST} -i 'sudo supervisorctl stop scollector'