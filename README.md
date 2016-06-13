# SwarmKit on Barge with Vagrant

https://github.com/docker/swarmkit
> SwarmKit is a toolkit for orchestrating distributed systems at any scale. It includes primitives for node discovery, raft-based consensus, task scheduling and more.

This shows how to create a SwarmKit cluster on [Barge](https://atlas.hashicorp.com/ailispaw/boxes/barge) with [Vagrant](https://www.vagrantup.com/) instantly.

It's inspired by
- [First Look at Docker SwarmKit | Replicated Blog](https://blog.replicated.com/2016/06/08/first-look-at-swarmkit/)
- [SwarmKit(Docker社製オーケストレーションツール) 触ってみた - Qiita](http://qiita.com/yamamoto-febc/items/705294a54e6051c3489c)

Please read them for further details.

## Requirements

- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)
- [vagrant-triggers](https://github.com/emyl/vagrant-triggers) (optional)  
  It will `git clone https://github.com/docker/swarmkit.git` on `vagrant up` automatically.

## Boot up

```bash
$ git clone https://github.com/ailispaw/swarmkit-barge
$ cd swarmkit-barge
$ git clone https://github.com/docker/swarmkit.git # if you don't have vagrant-triggers.
$ vagrant up
```

That's it.

## Tryout

```bash
$ vagrant ssh
[bargee@node-01 ~]$ export SWARM_SOCKET=/tmp/swarm/swarm.sock
[bargee@node-01 ~]$ swarmctl node ls
ID             Name     Membership  Status  Availability  Manager status
--             ----     ----------  ------  ------------  --------------
13rw9q5sp8xur  node-02  ACCEPTED    READY   ACTIVE
2h28d86n2h6gb  node-03  ACCEPTED    READY   ACTIVE
2qcb2624k0sgv  node-01  ACCEPTED    READY   ACTIVE        REACHABLE *
```

### Create a service

```bash
[bargee@node-01 ~]$ swarmctl service create --name redis --image redis:3.0.5
75wvz8i4fi0ld58x0maffni21
[bargee@node-01 ~]$ swarmctl service ls
ID                         Name   Image        Replicas
--                         ----   -----        --------
75wvz8i4fi0ld58x0maffni21  redis  redis:3.0.5  1
[bargee@node-01 ~]$ swarmctl service inspect redis
ID                : 75wvz8i4fi0ld58x0maffni21
Name              : redis
Replicas          : 1
Template
 Container
  Image           : redis:3.0.5

Task ID                      Service    Instance    Image          Desired State    Last State                  Node
-------                      -------    --------    -----          -------------    ----------                  ----
6hkyfdlc82se4ariplxr48rdo    redis      1           redis:3.0.5    RUNNING          PREPARING 20 seconds ago    node-01
[bargee@node-01 ~]$ docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED              STATUS              PORTS                    NAMES
abc77672fee6        redis:3.0.5         "/entrypoint.sh redis"   15 seconds ago       Up 15 seconds       6379/tcp                 redis.1.6hkyfdlc82se4ariplxr48rdo
576bda453e1e        ailispaw/swarmd     "swarmd -d /tmp/swarm"   About a minute ago   Up About a minute   0.0.0.0:4242->4242/tcp   swarmd
[bargee@node-01 ~]$ swarmctl service inspect redis
ID                : 75wvz8i4fi0ld58x0maffni21
Name              : redis
Replicas          : 1
Template
 Container
  Image           : redis:3.0.5

Task ID                      Service    Instance    Image          Desired State    Last State                Node
-------                      -------    --------    -----          -------------    ----------                ----
6hkyfdlc82se4ariplxr48rdo    redis      1           redis:3.0.5    RUNNING          RUNNING 56 seconds ago    node-01
```

## Update the service

```bash
[bargee@node-01 ~]$ swarmctl service update redis --replicas 3
75wvz8i4fi0ld58x0maffni21
[bargee@node-01 ~]$ swarmctl service inspect redis
ID                : 75wvz8i4fi0ld58x0maffni21
Name              : redis
Replicas          : 3
Template
 Container
  Image           : redis:3.0.5

Task ID                      Service    Instance    Image          Desired State    Last State                 Node
-------                      -------    --------    -----          -------------    ----------                 ----
6hkyfdlc82se4ariplxr48rdo    redis      1           redis:3.0.5    RUNNING          RUNNING 1 minute ago       node-01
an8vipicnteezox2or9i2p381    redis      2           redis:3.0.5    RUNNING          PREPARING 7 seconds ago    node-03
2ty0wo11gv6j2u2u9nf2ina9y    redis      3           redis:3.0.5    RUNNING          PREPARING 7 seconds ago    node-02
[bargee@node-01 ~]$ swarmctl service inspect redis
ID                : 75wvz8i4fi0ld58x0maffni21
Name              : redis
Replicas          : 3
Template
 Container
  Image           : redis:3.0.5

Task ID                      Service    Instance    Image          Desired State    Last State                Node
-------                      -------    --------    -----          -------------    ----------                ----
6hkyfdlc82se4ariplxr48rdo    redis      1           redis:3.0.5    RUNNING          RUNNING 1 minute ago      node-01
an8vipicnteezox2or9i2p381    redis      2           redis:3.0.5    RUNNING          RUNNING 31 seconds ago    node-03
2ty0wo11gv6j2u2u9nf2ina9y    redis      3           redis:3.0.5    RUNNING          RUNNING 31 seconds ago    node-02
```

## Drain a node

```bash
[bargee@node-01 ~]$ swarmctl node drain node-03
[bargee@node-01 ~]$ swarmctl service inspect redis
ID                : 75wvz8i4fi0ld58x0maffni21
Name              : redis
Replicas          : 3
Template
 Container
  Image           : redis:3.0.5

Task ID                      Service    Instance    Image          Desired State    Last State                Node
-------                      -------    --------    -----          -------------    ----------                ----
6hkyfdlc82se4ariplxr48rdo    redis      1           redis:3.0.5    RUNNING          RUNNING 2 minutes ago     node-01
4scza31mva21adl76fg4h5ast    redis      2           redis:3.0.5    RUNNING          RUNNING 4 seconds ago     node-02
2ty0wo11gv6j2u2u9nf2ina9y    redis      3           redis:3.0.5    RUNNING          RUNNING 51 seconds ago    node-02
```

## Remove the service

```bash
[bargee@node-01 ~]$ swarmctl service rm redis
redis
[bargee@node-01 ~]$ swarmctl service inspect redis
Error: service redis not found
[bargee@node-01 ~]$ swarmctl service ls
ID  Name  Image  Replicas
--  ----  -----  --------
[bargee@node-01 ~]$ docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
576bda453e1e        ailispaw/swarmd     "swarmd -d /tmp/swarm"   3 minutes ago       Up 3 minutes        0.0.0.0:4242->4242/tcp   swarmd
```
