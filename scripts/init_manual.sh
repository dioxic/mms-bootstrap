#!/usr/bin/env bash

sudo cp /data/automation-mongod.conf /etc/mongod.conf
sudo sed -i -e '/^  fork.*/a\' -e '  pidFilePath: /var/run/mongodb/mongod.pid' /etc/mongod.conf
sudo chown mongod: /etc/mongod.conf
sudo rm /var/run/mongodb/mongod.pid

sudo bash -c 'cat <<EOF > /etc/yum.repos.d/mongodb-org-3.4.repo
[mongodb-org-3.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2013.03/mongodb-org/3.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.4.asc
EOF'

sudo yum install -y mongodb-org

sudo service mongod start