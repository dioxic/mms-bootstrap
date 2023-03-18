#!/usr/bin/env bash

curl -OL ${mmsBaseUrl}/download/agent/automation/${agentRpm}
sudo rpm -U ${agentRpm}
sudo bash -c 'cat <<EOF > /etc/mongodb-mms/automation-agent.config
mmsGroupId=${mmsGroupId}
mmsApiKey=${mmsApiKey}
mmsBaseUrl=${mmsBaseUrl}

logFile=/var/log/mongodb-mms-automation/automation-agent.log
mmsConfigBackup=/var/lib/mongodb-mms-automation/mms-cluster-config-backup.json
logLevel=INFO
maxLogFiles=10
maxLogFileSize=268435456
EOF'

sudo mkdir /data
sudo chown mongod: /data
sudo rm -rf /data/*
sudo service mongodb-mms-automation-agent restart