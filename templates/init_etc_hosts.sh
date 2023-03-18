#!/usr/bin/env bash

sudo mv /etc/hosts /etc/hosts.orig

sudo bash -c 'cat <<EOF > /etc/hosts
%{ for host in hosts ~}
${host.ip}  ${host.fqdn}
%{ endfor ~}
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost6 localhost6.localdomain6
EOF'