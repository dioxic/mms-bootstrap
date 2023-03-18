#!/usr/bin/env bash

echo "running command on $1 hosts"

tf_output=$(terraform output -json)
public_ips=$(echo "$tf_output" | jq -r ".nodes_array.value | .[] | select(.type | contains(\"$1\")) | .public_ip")
ssh_username=$(echo "$tf_output" | jq -r ".ssh_username.value")
ssh_key_file=$(echo "$tf_output" | jq -r ".ssh_key_file.value")

echo "$public_ips" | while read i; do
  ssh -n -i "$ssh_key_file" "$ssh_username"@"$i" "$2"
done