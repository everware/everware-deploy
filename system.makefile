
NAMESERVER = 2a02:6b8:0:3400::1023
install-dns:
	${PSSH} -h ${CLUSTER_HOSTS} -H ${HEADHOST} -i 'echo "debconf resolvconf/linkify-resolvconf select true" | \
		sudo debconf-set-selections && sudo dpkg-reconfigure -f noninteractive resolvconf ; \
		sudo resolvconf --disable-updates && (sudo resolvconf --updates-are-enabled && echo Hmm || echo OK) ; \
		sudo sed -i -e "\$$ a nameserver ${NAMESERVER}" -e "/^nameserver/ d" /etc/resolv.conf \
	'
	${PSSH} -h ${CLUSTER_HOSTS} -i "sudo ip6tables -t nat -L POSTROUTING | grep MASQ || sudo ip6tables -t nat -I POSTROUTING -j MASQUERADE"

install-nfs-server:
	sudo apt-get install -y nfs-kernel-server
	mount | grep /mnt/shared
	sudo sed -i -e "\$$ a /mnt/shared *(rw,sync,no_root_squash)" -e "/^\/mnt\/shared/ d" /etc/exports
	sudo service nfs-kernel-server start

install-nfs-client:
	# ${PSSH} -h ${CLUSTER_HOSTS} -i 'sudo sed -i -e "\$$ a ${HEADHOST}:/mnt/shared /mnt/shared nfs rsize=8192,wsize=8192,timeo=14,intr" 
	${PSSH} -h ${CLUSTER_HOSTS} -i 'sudo sed -i -e "\$$ a ${HEADHOST}:/mnt/shared /mnt/shared nfs rsize=8192,wsize=8192,timeo=14,intr" \
		-e "/^${HEADHOST}/ d" /etc/fstab ; \
		sudo apt-get install -y nfs-common ; \
		sudo mkdir -p /mnt/shared ; \
		sudo mount /mnt/shared'

install-supervisor: ${CLUSTER_HOSTS}
	${PSSH} -h ${CLUSTER_HOSTS} -H ${HEADHOST} -i 'sudo apt-get install -y --force-yes supervisor'

system-check:
	${PSSH} -h ${CLUSTER_HOSTS} -H ${HEADHOST} -i "sudo ip6tables -t nat -L POSTROUTING | grep MASQ && \
		grep 'nameserver ${NAMESERVER}' /etc/resolv.conf && \
		test -d /mnt/shared/data && \
		dpkg -l | grep supervisor \
	"

