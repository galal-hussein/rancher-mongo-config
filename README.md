# rancher-mongo-config
A Base Docker image to be used as a sidekick for Mongodb container, the scripts in this container will create replica set when you create a service in Rancher environment (at least 3 containers).

## Requirements
- Docker engine
- Rancher server
- rancher-compose
## Usage

After installing rancher-compose, you can create a service that contain the following:

**docker-compose.yml**
```
mongo-cluster:
  restart: always
  environment:
    MONGO_SERVICE_NAME: mongo-cluster
  tty: true
  entrypoint: /opt/rancher/bin/entrypoint.sh
  command:
  - --replSet
  - "rs0"
  image: mongo:3.0
  labels:
    io.rancher.container.hostname_override: container_name
    io.rancher.sidekicks: mongo-base, mongo-datavolume
  volumes_from:
    - mongo-datavolume
    - mongo-base
mongo-base:
  restart: always
  tty: true
  labels:
    io.rancher.container.hostname_override: container_name
    io.rancher.container.start_once: true
  build: ./
  stdin_open: true
  entrypoint: /bin/true
mongo-datavolume:
  net: none
  labels:
    io.rancher.container.hostname_override: container_name
    io.rancher.container.start_once: true
  volumes:
    - /data/db
  entrypoint: /bin/true
  image: busybox
```
**rancher-compose.yml**
```
mongo-cluster:
  scale: 3
```

And now to run the service run the following:

```
# rancher-compose up
```
As a added bonus the service can scale up as you go, just change the settings in rancher-compose.yml or use the Web UI to scale the serivce and the container will connect to the replicaset and be attached.
