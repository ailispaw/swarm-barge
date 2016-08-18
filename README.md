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
Welcome to Barge 2.1.10, Docker version 1.12.1, build 23cf638
[bargee@node-01 ~]$ docker node ls
ID                           HOSTNAME  STATUS  AVAILABILITY  MANAGER STATUS
6qn4jov5n61v23beh0lqtngbl    node-03   Ready   Active
8g88v2jyf49lmwbnfxfsoofp5 *  node-01   Ready   Active        Leader
c84jsskhloiuwkf3tk35qrc7a    node-02   Ready   Active
```

### Create a service

```bash
[bargee@node-01 ~]$ docker service create --name vote -p 8080:80 instavote/vote
cf9rqqsg8emvx2x70ifxa8jbt
[bargee@node-01 ~]$ docker service ps vote
ID                         NAME    IMAGE           NODE     DESIRED STATE  CURRENT STATE          ERROR
1b5ebv79wqthx2wb8rsuu2srb  vote.1  instavote/vote  node-01  Running        Running 1 seconds ago
[bargee@node-01 ~]$  docker ps -a
CONTAINER ID        IMAGE                   COMMAND                  CREATED             STATUS              PORTS               NAMES
3df56eac0537        instavote/vote:latest   "gunicorn app:app -b "   17 seconds ago      Up 17 seconds       80/tcp              vote.1.1b5ebv79wqthx2wb8rsuu2srb
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
ID                         NAME    IMAGE           NODE     DESIRED STATE  CURRENT STATE           ERROR
1b5ebv79wqthx2wb8rsuu2srb  vote.1  instavote/vote  node-01  Running        Running 56 seconds ago
2zxiisw364edhwtddxlhe6lxv  vote.2  instavote/vote  node-03  Running        Running 2 seconds ago
0fol2vb3xd53vubfs2kgqltbi  vote.3  instavote/vote  node-02  Running        Running 1 seconds ago
```

## Check load balancing

```bash
[bargee@node-01 ~]$ sudo pkg install iproute2
[bargee@node-01 ~]$ sudo pkg install ipvsadm
[bargee@node-01 ~]$ sudo ls -l /var/run/docker/netns
total 0
-r--r--r--    1 root     root             0 Jul 28 05:38 1-3vmnixn0sn
-r--r--r--    1 root     root             0 Jul 28 05:38 3a7c705d0cdb
-r--r--r--    1 root     root             0 Jul 28 05:40 933e04568f99
[bargee@node-01 ~]$ sudo mkdir -p /var/run/netns
[bargee@node-01 ~]$ sudo ln -s /var/run/docker/netns/3a7c705d0cdb /var/run/netns/lbingress
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
6qn4jov5n61v23beh0lqtngbl    node-03   Ready   Drain
8g88v2jyf49lmwbnfxfsoofp5 *  node-01   Ready   Active        Leader
c84jsskhloiuwkf3tk35qrc7a    node-02   Ready   Active
[bargee@node-01 ~]$ docker service ps vote
ID                         NAME        IMAGE           NODE     DESIRED STATE  CURRENT STATE            ERROR
1b5ebv79wqthx2wb8rsuu2srb  vote.1      instavote/vote  node-01  Running        Running 2 minutes ago
1b4v6djht9cid9u0dtksth3r8  vote.2      instavote/vote  node-02  Running        Running 26 seconds ago
2zxiisw364edhwtddxlhe6lxv   \_ vote.2  instavote/vote  node-03  Shutdown       Shutdown 27 seconds ago
0fol2vb3xd53vubfs2kgqltbi  vote.3      instavote/vote  node-02  Running        Running 2 minutes ago
```

## Remove the service

```bash
[bargee@node-01 ~]$ docker service rm vote
vote
[bargee@node-01 ~]$ docker service ps vote
Error: No such service: vote
[bargee@node-01 ~]$ docker service ls
ID  NAME  REPLICAS  IMAGE  COMMAND
[bargee@node-01 ~]$ docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```
