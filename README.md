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
Welcome to Barge 2.5.7, Docker version 17.06.1-ce, build 874a737
[bargee@node-01 ~]$ docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS
oz072u285g5fe4pcghzgz4x09     node-02             Ready               Active
stjfxak0gzxx2krjirob0agm2     node-03             Ready               Active
tavg6m94d65i624dq8oiqm9mk *   node-01             Ready               Active              Leader
```

### Create a service

```bash
[bargee@node-01 ~]$ docker service create -d --name vote -p 8080:80 instavote/vote
2hlje9tlchhgviefq7snngmd6
[bargee@node-01 ~]$ docker service ps vote
ID                  NAME                IMAGE                   NODE                DESIRED STATE       CURRENT STATE                ERROR               PORTS
2fznq4mbkzu2        vote.1              instavote/vote:latest   node-01             Running             Running about a minute ago
[bargee@node-01 ~]$  docker ps -a
CONTAINER ID        IMAGE                   COMMAND                  CREATED              STATUS              PORTS               NAMES
61a6c9f4fa67        instavote/vote:latest   "gunicorn app:app ..."   About a minute ago   Up About a minute   80/tcp              vote.1.2fznq4mbkzu2dmshagjcosfhv
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
ID                  NAME                IMAGE                   NODE                DESIRED STATE       CURRENT STATE           ERROR               PORTS
2fznq4mbkzu2        vote.1              instavote/vote:latest   node-01             Running             Running 3 minutes ago
pdt27up379hp        vote.2              instavote/vote:latest   node-02             Running             Running 7 seconds ago
aty6tbypmyny        vote.3              instavote/vote:latest   node-03             Running             Running 7 seconds ago
```

## Check load balancing

```bash
[bargee@node-01 ~]$ sudo pkg install iproute2
[bargee@node-01 ~]$ sudo pkg install ipvsadm
[bargee@node-01 ~]$ sudo ls -l /var/run/docker/netns
total 0
-r--r--r--    1 root     root             0 Jun  1 08:37 1-m8wmvnvtij
-r--r--r--    1 root     root             0 Jun  1 08:40 ce6ce6a702bf
-r--r--r--    1 root     root             0 Jun  1 08:37 ingress_sbox
[bargee@node-01 ~]$ sudo mkdir -p /var/run/netns
[bargee@node-01 ~]$ sudo ln -s /var/run/docker/netns/ingress_sbox /var/run/netns/lbingress
[bargee@node-01 ~]$ sudo ip netns exec lbingress ipvsadm -L
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
FWM  256 rr
  -> 10.255.0.6:0                 Masq    1      0          3
  -> 10.255.0.7:0                 Masq    1      0          4
  -> 10.255.0.8:0                 Masq    1      0          4
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
oz072u285g5fe4pcghzgz4x09     node-02             Ready               Active
stjfxak0gzxx2krjirob0agm2     node-03             Ready               Drain
tavg6m94d65i624dq8oiqm9mk *   node-01             Ready               Active              Leader
[bargee@node-01 ~]$ docker service ps vote
ID                  NAME                IMAGE                   NODE                DESIRED STATE       CURRENT STATE                ERROR               PORTS
2fznq4mbkzu2        vote.1              instavote/vote:latest   node-01             Running             Running 5 minutes ago
pdt27up379hp        vote.2              instavote/vote:latest   node-02             Running             Running about a minute ago
htvzmykdvlor        vote.3              instavote/vote:latest   node-01             Running             Running 15 seconds ago
aty6tbypmyny         \_ vote.3          instavote/vote:latest   node-03             Shutdown            Shutdown 15 seconds ago
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
