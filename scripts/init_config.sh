#!/usr/bin/env bash

sudo mv /etc/mongod.conf /etc/mongod.conf.orig

sudo bash -c 'cat <<EOF > /etc/mongod.conf
net:
  bindIp: 0.0.0.0
  port: 27017
processManagement:
  fork: "true"
  pidFilePath: /var/run/mongodb/mongod.pid
replication:
  replSetName: csrs
sharding:
  clusterRole: configsvr
storage:
  dbPath: /data
systemLog:
  destination: file
  path: /data/mongodb.log
EOF'

sudo chown mongod: /etc/mongod.conf
sudo rm /var/run/mongodb/mongod.pid
sudo service mongod start
