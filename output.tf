#output "mms_public_ip" {
#  value = [aws_instance.mms.public_ip]
#}

#output "shard" {
#  value = [ for record in aws_instance.shard : record.public_ip ]
#}
#
#output "config" {
#  value = [ for record in aws_instance.config : record.public_ip ]
#}
#
#output "mongos" {
#  value = [ for record in aws_instance.mongos : record.public_ip ]
#}

#output "mms_public_dns" {
#  value = [aws_instance.mms.public_dns]
#}

#output "nodes_public_dns" {
#  value = [for record in aws_instance.node : record.public_dns]
#}
#
#output "nodes_public_ip" {
#  value = [for record in aws_instance.node : record.public_ip]
#}
#
#output "nodes_private_dns" {
#  value = [for record in aws_instance.node : record.private_dns]
#}

output "nodes" {
  value = {
    for k, v in local.nodes : k => {
      public_dns  = aws_instance.node[k].public_dns
      public_ip   = aws_instance.node[k].public_ip
      private_dns = aws_instance.node[k].private_dns
      private_ip  = aws_instance.node[k].private_ip
      type        = v["type"]
      fqdn        = v["fqdn"]
    }
  }
}

output "nodes_array" {
  value = [
    for k, v in local.nodes : {
      public_dns  = aws_instance.node[k].public_dns
      public_ip   = aws_instance.node[k].public_ip
      private_dns = aws_instance.node[k].private_dns
      private_ip  = aws_instance.node[k].private_ip
      name        = v["short_name"]
      type        = v["type"]
      fqdn        = v["fqdn"]
    }
  ]
}

#output "shard_dns" {
#  value = [ for record in aws_instance.shard : record.private_dns ]
#}
#
#output "config_dns" {
#  value = [ for record in aws_instance.config : record.private_dns ]
#}
#
#output "mongos_dns" {
#  value = [ for record in aws_instance.mongos : record.private_dns ]
#}

output "ssh_key_file" {
  value = var.ssh_key_file
}

output "ssh_username" {
  value = var.ssh_username
}

#output "route53_fqdn" {
#  value = [for record in aws_route53_record.nodes : record.fqdn]
#}

#output "nodes" {
#  value = local.nodes
#}