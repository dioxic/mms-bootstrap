#!/usr/bin/env bash

echo "scp $2 to $1 hosts"

tf_output=$(terraform output -json)
public_ips=$(echo "$tf_output" | jq -r ".nodes_array.value | .[] | select(.type | contains(\"$1\")) | .public_ip")
ssh_username=$(echo "$tf_output" | jq -r ".ssh_username.value")
ssh_key_file=$(echo "$tf_output" | jq -r ".ssh_key_file.value")

echo "$public_ips" | while read i; do
  #echo "$i $2 $ssh_key_file $ssh_username"
  #echo "$ssh_username@$i:/home/$ssh_username/myScript.sh"
  scp -i "$ssh_key_file" -o "StrictHostKeyChecking=no" "$2" "$ssh_username"@"$i":/home/"$ssh_username"/$(basename $2)
done