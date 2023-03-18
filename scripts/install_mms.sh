#!/usr/bin/env bash

sudo tee /etc/yum.repos.d/mongodb-enterprise-4.4.repo > /dev/null <<'EOF'
[mongodb-enterprise-6.0]
name=MongoDB Enterprise Repository
baseurl=https://repo.mongodb.com/yum/amazon/2/mongodb-enterprise/6.0/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF

sudo yum update -y
sudo yum install -y mongodb-enterprise

#https://downloads.mongodb.com/on-prem-mms/rpm/mongodb-mms-5.0.15.100.20220916T2105Z-1.x86_64.rpm
#https://downloads.mongodb.com/on-prem-mms/rpm/mongodb-mms-5.0.17.100.20221115T1043Z-1.x86_64.rpm
OM_RPM=mongodb-mms-6.0.3.100.20220830T1616Z.x86_64.rpm

if test -f "$OM_RPM"; then
  echo "Ops Manager already installed"
else
  curl -OL https://downloads.mongodb.com/on-prem-mms/rpm/$OM_RPM
  sudo rpm -ivh $OM_RPM
fi

sudo systemctl start mongod
sudo service mongodb-mms start