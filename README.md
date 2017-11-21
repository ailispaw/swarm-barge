# Docker Swarm Mode on Barge with Vagrant

This shows how to create a Docker Swarm cluster on [Barge](https://atlas.hashicorp.com/ailispaw/boxes/barge) with Docker Swarm Mode and [Vagrant](https://www.vagrantup.com/) instantly.

It's inspired by DockerCon16 KeyNote and "What's New in Docker" session.

## Requirements

- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)

## Boot up

```bash
$ git clone https://github.com/ailispaw/swarm-barge
$ cd swarm-barge
$ make up
```

That's it.

## Tryout

```bash
$ ssh -F .ssh_config node-01
Welcome to Barge 2.6.2, Docker version 17.11.0-ce, build 1caf76c
[bargee@node-01 ~]$ docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS
h7edyaxyecsgfknmemxfs2nfg *   node-01             Ready               Active              Leader
cq7em3k7l9grtu9qtmpyt0b22     node-02             Ready               Active
wtjh4uh9qao20j96vtdhya0eh     node-03             Ready               Active
```

### Create a service

```bash
[bargee@node-01 ~]$ docker service create -d --name vote -p 8080:80 instavote/vote
8rarm6anpwoi2bdgh9epl352j
[bargee@node-01 ~]$ docker service ps vote
ID                  NAME                IMAGE                   NODE                DESIRED STATE       CURRENT STATE          ERROR               PORTS
t2w6e990h9tt        vote.1              instavote/vote:latest   node-01             Running             Running 1 second ago
[bargee@node-01 ~]$  docker ps -a
CONTAINER ID        IMAGE                   COMMAND                  CREATED             STATUS              PORTS               NAMES
f6e6009dbac9        instavote/vote:latest   "gunicorn app:app ..."   17 seconds ago      Up 16 seconds       80/tcp              vote.1.t2w6e990h9tt8bwe7syy4m9pj
```

```bash
$ open http://192.168.65.101:8080/
```

![Cats vs Dogs!](https://65.media.tumblr.com/7219623b72287a3f2593c7c279cb8c41/tumblr_o9p000HMuk1u7n3kzo1_1280.png)

## Update the service

```bash
[bargee@node-01 ~]$ docker service scale vote=3
vote scaled to 3
overall progress: 3 out of 3 tasks
1/3: running   [==================================================>]
2/3: running   [==================================================>]
3/3: running   [==================================================>]
verify: Service converged
[bargee@node-01 ~]$ docker service ps vote
ID                  NAME                IMAGE                   NODE                DESIRED STATE       CURRENT STATE                ERROR               PORTS
t2w6e990h9tt        vote.1              instavote/vote:latest   node-01             Running             Running about a minute ago
7ikfah5ba5gt        vote.2              instavote/vote:latest   node-02             Running             Running 20 seconds ago
sc2c5lnlkezf        vote.3              instavote/vote:latest   node-03             Running             Running 21 seconds ago
```

## Check load balancing

```bash
[bargee@node-01 ~]$ sudo pkg install iproute2
[bargee@node-01 ~]$ sudo pkg install ipvsadm
[bargee@node-01 ~]$ sudo ls -l /var/run/docker/netns
total 0
-r--r--r--    1 root     root             0 Oct 18 18:26 1-94du9n58gw
-r--r--r--    1 root     root             0 Oct 18 18:27 b973053ec9b7
-r--r--r--    1 root     root             0 Oct 18 18:26 ingress_sbox
[bargee@node-01 ~]$ sudo mkdir -p /var/run/netns
[bargee@node-01 ~]$ sudo ln -s /var/run/docker/netns/ingress_sbox /var/run/netns/lbingress
[bargee@node-01 ~]$ sudo ip netns exec lbingress ipvsadm -L
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
FWM  256 rr
  -> 10.255.0.6:0                 Masq    1      0          2
  -> 10.255.0.7:0                 Masq    1      0          0
  -> 10.255.0.8:0                 Masq    1      0          0
```

```bash
$ open http://192.168.65.101:8080/
```

You will see 3 container ID at the bottom of the page on each reloading.

And the following as well.

```bash
$ open http://192.168.65.102:8080/
$ open http://192.168.65.103:8080/
```

## Drain a node

```bash
[bargee@node-01 ~]$ docker node update --availability=drain node-03
node-03
[bargee@node-01 ~]$ docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS
h7edyaxyecsgfknmemxfs2nfg *   node-01             Ready               Active              Leader
cq7em3k7l9grtu9qtmpyt0b22     node-02             Ready               Active
wtjh4uh9qao20j96vtdhya0eh     node-03             Ready               Drain
[bargee@node-01 ~]$ docker service ps vote
ID                  NAME                IMAGE                   NODE                DESIRED STATE       CURRENT STATE             ERROR               PORTS
t2w6e990h9tt        vote.1              instavote/vote:latest   node-01             Running             Running 3 minutes ago
7ikfah5ba5gt        vote.2              instavote/vote:latest   node-02             Running             Running 2 minutes ago
le7ocmmwplwr        vote.3              instavote/vote:latest   node-02             Running             Running 18 seconds ago
sc2c5lnlkezf         \_ vote.3          instavote/vote:latest   node-03             Shutdown            Shutdown 18 seconds ago
```

## Remove the service

```bash
[bargee@node-01 ~]$ docker service rm vote
vote
[bargee@node-01 ~]$ docker service ps vote
no such services: vote
[bargee@node-01 ~]$ docker service ls
ID                  NAME                MODE                REPLICAS            IMAGE               PORTS
[bargee@node-01 ~]$ docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```
