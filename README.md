# Docker v1.12 Swarm Mode on Barge with Vagrant

This shows how to create a Docker Swarm cluster on [Barge](https://atlas.hashicorp.com/ailispaw/boxes/barge) with Docker v1.12 Swarm Mode and [Vagrant](https://www.vagrantup.com/) instantly.

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
Welcome to Barge 2.4.3, Docker version 17.03.1-ce, build c6d412e
[bargee@node-01 ~]$ docker node ls
ID                           HOSTNAME  STATUS  AVAILABILITY  MANAGER STATUS
o53sr6hv3u6by04pqfh5fubs9    node-02   Ready   Active
t6jtlv212jq0l0ygkxh5frqjs *  node-01   Ready   Active        Leader
wdrikpbhao504p9qdu5equarv    node-03   Ready   Active
```

### Create a service

```bash
[bargee@node-01 ~]$ docker service create --name vote -p 8080:80 instavote/vote
qi3lkspe97g8au1c8pr7bchr9
[bargee@node-01 ~]$ docker service ps vote
ID            NAME    IMAGE                  NODE     DESIRED STATE  CURRENT STATE           ERROR  PORTS
zgvseq334tvy  vote.1  instavote/vote:latest  node-01  Running        Running 15 seconds ago
[bargee@node-01 ~]$  docker ps -a
CONTAINER ID        IMAGE                                                                                    COMMAND                  CREATED             STATUS              PORTS               NAMES
bc996c0a616b        instavote/vote@sha256:744fb4b71488d8a925b519846dcc3b4463bde829457e912bd47ef8da36a93bd6   "gunicorn app:app ..."   40 seconds ago      Up 39 seconds       80/tcp              vote.1.zgvseq334tvya915aat5wtrvn
```

```bash
$ open http://192.168.65.101:8080/
```

![Cats vs Dogs!](https://65.media.tumblr.com/7219623b72287a3f2593c7c279cb8c41/tumblr_o9p000HMuk1u7n3kzo1_1280.png)

## Update the service

```bash
[bargee@node-01 ~]$ docker service scale vote=3
vote scaled to 3
[bargee@node-01 ~]$ docker service ps vote
ID            NAME    IMAGE                  NODE     DESIRED STATE  CURRENT STATE               ERROR  PORTS
zgvseq334tvy  vote.1  instavote/vote:latest  node-01  Running        Running about a minute ago
9fc9sy2xpryx  vote.2  instavote/vote:latest  node-02  Running        Running 7 seconds ago
l8fk88ghq0qr  vote.3  instavote/vote:latest  node-03  Running        Running 1 second ago
```

## Check load balancing

```bash
[bargee@node-01 ~]$ sudo pkg install iproute2
[bargee@node-01 ~]$ sudo pkg install ipvsadm
[bargee@node-01 ~]$ sudo ls -l /var/run/docker/netns
total 0
-r--r--r--    1 root     root             0 Feb 10 00:12 1-jx1sqnzkcf
-r--r--r--    1 root     root             0 Feb 10 00:15 8cc87d05caa8
-r--r--r--    1 root     root             0 Feb 10 00:12 ingress_sbox
[bargee@node-01 ~]$ sudo mkdir -p /var/run/netns
[bargee@node-01 ~]$ sudo ln -s /var/run/docker/netns/ingress_sbox /var/run/netns/lbingress
[bargee@node-01 ~]$ sudo ip netns exec lbingress ipvsadm -L
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
FWM  256 rr
  -> 10.255.0.7:0                 Masq    1      0          0
  -> 10.255.0.8:0                 Masq    1      0          0
  -> 10.255.0.9:0                 Masq    1      0          0
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
ID                           HOSTNAME  STATUS  AVAILABILITY  MANAGER STATUS
o53sr6hv3u6by04pqfh5fubs9    node-02   Ready   Active
t6jtlv212jq0l0ygkxh5frqjs *  node-01   Ready   Active        Leader
wdrikpbhao504p9qdu5equarv    node-03   Ready   Drain
[bargee@node-01 ~]$ docker service ps vote
ID            NAME        IMAGE                  NODE     DESIRED STATE  CURRENT STATE               ERROR  PORTS
zgvseq334tvy  vote.1      instavote/vote:latest  node-01  Running        Running 2 minutes ago
9fc9sy2xpryx  vote.2      instavote/vote:latest  node-02  Running        Running about a minute ago
j025wpysc5nz  vote.3      instavote/vote:latest  node-01  Running        Running 15 seconds ago
l8fk88ghq0qr   \_ vote.3  instavote/vote:latest  node-03  Shutdown       Shutdown 15 seconds ago
```

## Remove the service

```bash
[bargee@node-01 ~]$ docker service rm vote
vote
[bargee@node-01 ~]$ docker service ps vote
Error: No such service: vote
[bargee@node-01 ~]$ docker service ls
ID  NAME  MODE  REPLICAS  IMAGE
[bargee@node-01 ~]$ docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```
