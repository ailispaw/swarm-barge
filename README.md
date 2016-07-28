# Docker v1.12 Swarm Mode on Barge with Vagrant

This shows how to create a Docker Swarm cluster on [Barge](https://atlas.hashicorp.com/ailispaw/boxes/barge) with Docker v1.12 Swarm Mode and [Vagrant](https://www.vagrantup.com/) instantly.

It's inspired by DockerCon16 KeyNote and "What's New in Docker" session.

## Requirements

- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)

## Boot up

```bash
$ git clone https://github.com/ailispaw/swarmkit-barge
$ cd swarmkit-barge
$ make up
```

That's it.

## Tryout

```bash
$ ssh -F .ssh_config node-01
Welcome to Barge 2.1.8, Docker version 1.12.0-rc5, build a3f2063
[bargee@node-01 ~]$ docker node ls
ID                           HOSTNAME  MEMBERSHIP  STATUS  AVAILABILITY  MANAGER STATUS
696cma420rjypkftujrpxmqs2 *  node-01   Accepted    Ready   Active        Leader
c2zz4w65vii7g7nzj6quyi16g    node-03   Accepted    Ready   Active
eu4th28cf2yhpyv95ywkadpjf    node-02   Accepted    Ready   Active
```

### Create a service

```bash
[bargee@node-01 ~]$ docker service create --name vote -p 8080:80 instavote/vote
283tgaj9oq493hkeochnhyl4m
[bargee@node-01 ~]$ docker service tasks vote
ID                         NAME    SERVICE  IMAGE           LAST STATE          DESIRED STATE  NODE
6wdivw267q1s0cpqbnuve6dlr  vote.1  vote     instavote/vote  Running 13 seconds  Running        node-01
[bargee@node-01 ~]$  docker ps -a
CONTAINER ID        IMAGE                   COMMAND                  CREATED             STATUS              PORTS               NAMES
c35944b92124        instavote/vote:latest   "gunicorn app:app -b "   22 seconds ago      Up 21 seconds       80/tcp              vote.1.6wdivw267q1s0cpqbnuve6dlr
```

```bash
$ open http://192.168.65.101:8080/
```

![Cats vs Dogs!](https://65.media.tumblr.com/7219623b72287a3f2593c7c279cb8c41/tumblr_o9p000HMuk1u7n3kzo1_1280.png)

## Update the service

```bash
[bargee@node-01 ~]$ docker service scale vote=3
vote scaled to 3
[bargee@node-01 ~]$ docker service tasks vote
ID                         NAME    SERVICE  IMAGE           LAST STATE              DESIRED STATE  NODE
6wdivw267q1s0cpqbnuve6dlr  vote.1  vote     instavote/vote  Running About a minute  Running        node-01
4y0u0gsfj3hkumbov6bcjqgm0  vote.2  vote     instavote/vote  Running 11 seconds      Running        node-02
b7sfv3oskjjt5l21seo3f7u60  vote.3  vote     instavote/vote  Running 11 seconds      Running        node-03
```

## Check load balancing

```bash
[bargee@node-01 ~]$ sudo pkg install iproute2
[bargee@node-01 ~]$ sudo pkg install ipvsadm
[bargee@node-01 ~]$ sudo ls -l /var/run/docker/netns
total 0
-r--r--r--    1 root     root             0 Jul  2 14:35 1-cju9mci9kf
-r--r--r--    1 root     root             0 Jul  2 14:35 29891f6354a1
-r--r--r--    1 root     root             0 Jul  2 14:41 ab8827aaaf47
[bargee@node-01 ~]$ sudo mkdir -p /var/run/netns
[bargee@node-01 ~]$ sudo ln -s /var/run/docker/netns/29891f6354a1 /var/run/netns/lbingress
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
ID                           HOSTNAME  MEMBERSHIP  STATUS  AVAILABILITY  MANAGER STATUS
696cma420rjypkftujrpxmqs2 *  node-01   Accepted    Ready   Active        Leader
c2zz4w65vii7g7nzj6quyi16g    node-03   Accepted    Ready   Drain
eu4th28cf2yhpyv95ywkadpjf    node-02   Accepted    Ready   Active
[bargee@node-01 ~]$ docker service tasks vote
ID                         NAME    SERVICE  IMAGE           LAST STATE          DESIRED STATE  NODE
6wdivw267q1s0cpqbnuve6dlr  vote.1  vote     instavote/vote  Running 15 minutes  Running        node-01
4y0u0gsfj3hkumbov6bcjqgm0  vote.2  vote     instavote/vote  Running 14 minutes  Running        node-02
ao5f31wriza473kz6ypt24l0h  vote.3  vote     instavote/vote  Running 25 seconds  Running        node-02
```

## Remove the service

```bash
[bargee@node-01 ~]$ docker service rm vote
vote
[bargee@node-01 ~]$ docker service tasks redis
Error: No such service: vote
[bargee@node-01 ~]$ docker service ls
ID  NAME  REPLICAS  IMAGE  COMMAND
[bargee@node-01 ~]$ docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```
