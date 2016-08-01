NODES := node-01 node-02 node-03

SSH_CONFIG := .ssh_config

GET_IP  := ifconfig eth1 | awk '/inet addr/{print substr(\\$$2,6)}'
NODE_IP := `ssh -F $(SSH_CONFIG) node "$(GET_IP)"`

up: $(NODES)

node-01:
	vagrant up $@
	vagrant ssh-config $@ > $(SSH_CONFIG)

	ssh -F $(SSH_CONFIG) $@ /opt/bin/docker swarm init --advertise-addr "$(NODE_IP:node=$@):2377"

node-02 node-03:
	vagrant up $@
	@if ! grep -q $@ $(SSH_CONFIG); then \
		vagrant ssh-config $@ >> $(SSH_CONFIG); \
	fi

	$(eval TOKEN=$$(shell ssh -F $(SSH_CONFIG) node-01 /opt/bin/docker swarm join-token --quiet worker))

	ssh -F $(SSH_CONFIG) $@ /opt/bin/docker swarm join --token "$(TOKEN)" "$(NODE_IP:node=node-01):2377"

status:
	ssh -F $(SSH_CONFIG) node-01 /opt/bin/docker node ls

clean:
	vagrant destroy -f
	$(RM) -r .vagrant
	$(RM) $(SSH_CONFIG)

.PHONY: up $(NODES) status clean
