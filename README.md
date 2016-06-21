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
Welcome to Barge 2.1.2, Docker version 1.12.0-rc2, build 906eacd
[bargee@node-01 ~]$ docker node ls
ID                           NAME     MEMBERSHIP  STATUS  AVAILABILITY  MANAGER STATUS
0kfhm60hjn9jekz5oyz9h7k9q    node-02  Accepted    Ready   Active
6lmenrr5upb4g0lh2xo2af3ge    node-03  Accepted    Ready   Active
86tqrcxwnquoaoqet5j2ba2mn *  node-01  Accepted    Ready   Active        Leader
```

### Create a service

```bash
[bargee@node-01 ~]$ docker service create --name redis redis:3.0.5
7kqyo9dc0prjatf1mv6uwekgr
[bargee@node-01 ~]$ docker service tasks redis
ID                         NAME     SERVICE  IMAGE        LAST STATE           DESIRED STATE  NODE
cka3zmfkskbhz8lgmgo52x6kg  redis.1  redis    redis:3.0.5  Preparing 9 seconds  Running        node-01
[bargee@node-01 ~]$ docker service tasks redis
ID                         NAME     SERVICE  IMAGE        LAST STATE              DESIRED STATE  NODE
cka3zmfkskbhz8lgmgo52x6kg  redis.1  redis    redis:3.0.5  Running About a minute  Running        node-01
[bargee@node-01 ~]$ docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
12e79bfb525f        redis:3.0.5         "/entrypoint.sh redis"   15 seconds ago      Up 14 seconds       6379/tcp            redis.1.cka3zmfkskbhz8lgmgo52x6kg
```

## Update the service

```bash
[bargee@node-01 ~]$ docker service update --replicas=3 redis
redis
[bargee@node-01 ~]$ docker service tasks redis
ID                         NAME     SERVICE  IMAGE        LAST STATE              DESIRED STATE  NODE
cka3zmfkskbhz8lgmgo52x6kg  redis.1  redis    redis:3.0.5  Running About a minute  Running        node-01
ey3pzccxqoai9riwkbz3duuq0  redis.2  redis    redis:3.0.5  Preparing 4 seconds     Running        node-03
egjdih78si559rqllyx1m4gjm  redis.3  redis    redis:3.0.5  Preparing 4 seconds     Running        node-02
[bargee@node-01 ~]$ docker service tasks redis
ID                         NAME     SERVICE  IMAGE        LAST STATE         DESIRED STATE  NODE
cka3zmfkskbhz8lgmgo52x6kg  redis.1  redis    redis:3.0.5  Running 3 minutes  Running        node-01
ey3pzccxqoai9riwkbz3duuq0  redis.2  redis    redis:3.0.5  Running 2 minutes  Running        node-03
egjdih78si559rqllyx1m4gjm  redis.3  redis    redis:3.0.5  Running 2 minutes  Running        node-02
```

## Drain a node

```bash
[[bargee@node-01 ~]$ docker node update --availability=drain node-03
node-03
[bargee@node-01 ~]$ docker node ls
ID                           NAME     MEMBERSHIP  STATUS  AVAILABILITY  MANAGER STATUS
0kfhm60hjn9jekz5oyz9h7k9q    node-02  Accepted    Ready   Active
6lmenrr5upb4g0lh2xo2af3ge    node-03  Accepted    Ready   Drain
86tqrcxwnquoaoqet5j2ba2mn *  node-01  Accepted    Ready   Active        Leader
[bargee@node-01 ~]$ docker service tasks redis
ID                         NAME     SERVICE  IMAGE        LAST STATE          DESIRED STATE  NODE
cka3zmfkskbhz8lgmgo52x6kg  redis.1  redis    redis:3.0.5  Running 4 minutes   Running        node-01
dmjv0n4n2dceex1mldw1o12r6  redis.2  redis    redis:3.0.5  Running 17 seconds  Running        node-02
egjdih78si559rqllyx1m4gjm  redis.3  redis    redis:3.0.5  Running 2 minutes   Running        node-02
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
