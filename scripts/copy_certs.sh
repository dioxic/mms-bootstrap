#!/usr/bin/env bash

echo "copying certs to all hosts"

tf_output=$(terraform output -json)
node_count=$(echo "$tf_output" | jq -r ".nodes_array.value | length")
nodes=$(echo "$tf_output" | jq -r ".nodes_array.value")
ssh_username=$(echo "$tf_output" | jq -r ".ssh_username.value")
ssh_key_file=$(echo "$tf_output" | jq -r ".ssh_key_file.value")

for (( i=0; i<$node_count; i++ ))
do
  node_name=$(echo "$tf_output" | jq -r ".nodes_array.value | .[$i] | .name")
  cert_name="$node_name"-s.pem
  public_ip=$(echo "$tf_output" | jq -r ".nodes_array.value | .[$i] | .public_ip")
  scp -i "$ssh_key_file" -o "StrictHostKeyChecking=no" "generated/certs/$cert_name" "$ssh_username"@"$public_ip":/home/"$ssh_username"/$(basename server.pem)
done

for (( i=0; i<$node_count; i++ ))
do
  node_name=$(echo "$tf_output" | jq -r ".nodes_array.value | .[$i] | .name")
  cert_name="$node_name"-c.pem
  public_ip=$(echo "$tf_output" | jq -r ".nodes_array.value | .[$i] | .public_ip")
  scp -i "$ssh_key_file" -o "StrictHostKeyChecking=no" "generated/certs/$cert_name" "$ssh_username"@"$public_ip":/home/"$ssh_username"/$(basename client.pem)
done

for (( i=0; i<$node_count; i++ ))
do
  node_name=$(echo "$tf_output" | jq -r ".nodes_array.value | .[$i] | .name")
  cert_name="$node_name"-sc.pem
  public_ip=$(echo "$tf_output" | jq -r ".nodes_array.value | .[$i] | .public_ip")
  scp -i "$ssh_key_file" -o "StrictHostKeyChecking=no" "generated/certs/$cert_name" "$ssh_username"@"$public_ip":/home/"$ssh_username"/$(basename sc.pem)
done

for (( i=0; i<$node_count; i++ ))
do
  node_name=$(echo "$tf_output" | jq -r ".nodes_array.value | .[$i] | .name")
  public_ip=$(echo "$tf_output" | jq -r ".nodes_array.value | .[$i] | .public_ip")
  scp -i "$ssh_key_file" -o "StrictHostKeyChecking=no" "generated/certs/user.pem" "$ssh_username"@"$public_ip":/home/"$ssh_username"/$(basename user.pem)
done

for (( i=0; i<$node_count; i++ ))
do
  node_name=$(echo "$tf_output" | jq -r ".nodes_array.value | .[$i] | .name")
  public_ip=$(echo "$tf_output" | jq -r ".nodes_array.value | .[$i] | .public_ip")
  scp -i "$ssh_key_file" -o "StrictHostKeyChecking=no" "certs/ca.crt" "$ssh_username"@"$public_ip":/home/"$ssh_username"/$(basename ca.crt)
done

#echo "$public_ips" | while read i; do
#  scp -i "$ssh_key_file" -o "StrictHostKeyChecking=no" "$2" "$ssh_username"@"$i":/home/"$ssh_username"/$(basename $2)
#done