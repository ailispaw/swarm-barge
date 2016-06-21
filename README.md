# Docker v1.12 Swarm Mode on Barge with Vagrant

This shows how to create a Docker Swarm cluster on [Barge](https://atlas.hashicorp.com/ailispaw/boxes/barge) with Docker v1.12 Swarm Mode and [Vagrant](https://www.vagrantup.com/) instantly.

It's inspired by DockerCon16 KeyNote and "What's New in Docker" session.

## Requirements

- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)

## Boot up

```bash
$ git clone -b docker-1.12 https://github.com/ailispaw/swarmkit-barge
$ cd swarmkit-barge
$ vagrant up
```

That's it.

## Tryout

```bash
$ vagrant ssh
[bargee@node-01 ~]$ docker node ls
ID                           NAME     MEMBERSHIP  STATUS  AVAILABILITY  MANAGER STATUS
318oexxpzl38dbgauj4ip8f16    node-02  Accepted    Ready   Active
43kteyorgncwthoi5zn3dyt3q    node-03  Accepted    Ready   Active
dxrf0lrd3ed7hhv77nrkjruw0 *  node-01  Accepted    Ready   Active        Leader
```

### Create a service

```bash
[bargee@node-01 ~]$ docker service create --name redis redis:3.0.5
9zyzpbinl1k9uxp7h7m9lb434
[bargee@node-01 ~]$ docker service ls
ID            NAME   REPLICAS  IMAGE        COMMAND
9zyzpbinl1k9  redis  0/1       redis:3.0.5
[bargee@node-01 ~]$ docker service tasks redis
ID                         NAME     SERVICE  IMAGE        LAST STATE          DESIRED STATE  NODE
c31w8247nc09y6nfai8hp0xal  redis.1  redis    redis:3.0.5  Running 59 seconds  Running        node-01
[bargee@node-01 ~]$ docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
98ed65c3640b        redis:3.0.5         "/entrypoint.sh redis"   38 seconds ago      Up 37 seconds       6379/tcp            redis.1.c31w8247nc09y6nfai8hp0xal
```

## Update the service

```bash
[bargee@node-01 ~]$ docker service update --replicas=3 redis
redis
[bargee@node-01 ~]$ docker service tasks redis
ID                         NAME     SERVICE  IMAGE        LAST STATE            DESIRED STATE  NODE
c31w8247nc09y6nfai8hp0xal  redis.1  redis    redis:3.0.5  Running 4 minutes     Running        node-01
1lg58ghbj36iyy2915w0e3mp5  redis.2  redis    redis:3.0.5  Preparing 13 seconds  Running        node-03
3m8oridvds3rjwxcwz4aivgdk  redis.3  redis    redis:3.0.5  Preparing 13 seconds  Running        node-02
```

## Drain a node

```bash
[[bargee@node-01 ~]$ docker node update --availability=drain node-03
node-03
[bargee@node-01 ~]$ docker node ls
ID                           NAME     MEMBERSHIP  STATUS  AVAILABILITY  MANAGER STATUS
318oexxpzl38dbgauj4ip8f16    node-02  Accepted    Ready   Active
43kteyorgncwthoi5zn3dyt3q    node-03  Accepted    Ready   Drain
dxrf0lrd3ed7hhv77nrkjruw0 *  node-01  Accepted    Ready   Active        Leader
[bargee@node-01 ~]$ docker service tasks redis
ID                         NAME     SERVICE  IMAGE        LAST STATE          DESIRED STATE  NODE
c31w8247nc09y6nfai8hp0xal  redis.1  redis    redis:3.0.5  Running 8 minutes   Running        node-01
dpj8u02dkeytm0x3dgtgcuf8e  redis.2  redis    redis:3.0.5  Running 26 seconds  Running        node-02
3m8oridvds3rjwxcwz4aivgdk  redis.3  redis    redis:3.0.5  Running 3 minutes   Running        node-02
```

## Remove the service

```bash
[bargee@node-01 ~]$ docker service rm redis
redis
[bargee@node-01 ~]$ docker service tasks redis
Error: No such service: redis
[bargee@node-01 ~]$ docker service ls
ID  NAME  REPLICAS  IMAGE  COMMAND
[bargee@node-01 ~]$ docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```
