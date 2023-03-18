#!/usr/bin/env bash

sudo mv ~/mongos.init.d /etc/init.d/mongos
sudo mv ~/mongos.conf /etc/mongos.conf
sudo chown mongod: /etc/mongos.conf
sudo rm /var/run/mongodb/mongos.pid
sudo service mongos restart
