#!/usr/bin/env bash

echo "connecting to $1 $2"

tf_output=$(terraform output -json)
public_ip=$(echo "$tf_output" | jq -r ".nodes.value.$1.public_ip")
ssh_username=$(echo "$tf_output" | jq -r ".ssh_username.value")
ssh_key_file=$(echo "$tf_output" | jq -r ".ssh_key_file.value")

echo "$public_ip"

ssh -o "StrictHostKeyChecking=no" -i "$ssh_key_file" "$ssh_username"@"$public_ip"