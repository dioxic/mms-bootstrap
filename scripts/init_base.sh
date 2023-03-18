#!/usr/bin/env bash

#sudo bash -c 'cat <<EOF > /etc/yum.repos.d/mongodb-org-6.0.repo
#[mongodb-org-6.0]
#name=MongoDB Repository
#baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/6.0/$basearch/
#gpgcheck=1
#enabled=1
#gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
#EOF'

sudo tee /etc/yum.repos.d/mongodb-org-6.0.repo > /dev/null <<'EOF'
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/$releasever/mongodb-org/6.0/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
EOF

sudo yum update -y
sudo yum install -y cyrus-sasl cyrus-sasl-plain cyrus-sasl-gssapi krb5-libs libcurl libpcap net-snmp openldap openssl
sudo yum install -y mongodb-mongosh
