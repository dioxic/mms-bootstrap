provider "aws" {
  region = "eu-west-1"
}

data "aws_region" "current" {}

data "aws_ami" "amzn1" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "template_cloudinit_config" "base" {
  for_each = local.nodes

  gzip          = true
  base64_encode = true

  dynamic "part" {
    for_each = each.value["user_data"]
    content {
      filename     = part.value["filename"]
      content_type = part.value["content_type"]
      content      = part.value["content"]
      merge_type   = "list(append)+dict(recurse_array)+str()"
    }
  }
}

locals {
  ssh_private_key = file(var.ssh_key_file)
  nodes_by_name   = {
    for t in var.nodes : t.name => [
      for i in range(t.count) : {
        name             = "${var.name}-${t.name}${i}",
        short_name       = "${t.name}${i}",
        fqdn             = "${var.name}-${t.name}${i}.${var.zone_domain}",
        type             = t.name,
        groups           = t.groups,
        mms_project      = t.mms_project,
        root_volume_size = t.root_volume_size,
        data_volume_size = t.data_volume_size,
        instance_type    = t.instance_type,
        idx              = i,
        user_data        = [
          {
            filename     = "base-init.cfg"
            content_type = "text/cloud-config"
            content      = templatefile("${path.module}/templates/cloud-init-base.yaml", {
              fqdn = "${var.name}-${t.name}${i}.${var.zone_domain}"
            })
          }
        ]
      }
    ]
  }
  nodes_array         = flatten([for k, v in local.nodes_by_name : v])
  nodes               = {for n in local.nodes_array : n["short_name"] => n}
  groups              = distinct(flatten([for n in local.nodes_array : n["groups"]]))
  webapp_nodes_array  = [for n in local.nodes_array : n if contains(n["groups"], "webapp")]
  webapp_nodes        = {for k, v in local.nodes : k => v if contains(v["groups"], "webapp")}
  webapp_instance_ids = [for k, v in aws_instance.node : v["id"] if contains(keys(local.webapp_nodes), k)]
}

// --------- SECURITY GROUPS ---------

resource "aws_security_group" "mongodb" {
  name_prefix = "${var.name}-mongodb-"
  vpc_id      = data.aws_vpc.default.id
  description = "MongoDB security group"

  tags = merge(
    {
      "Name" = "${var.name}-mongodb"
    },
    var.tags
  )
}

resource "aws_security_group_rule" "self_mongod" {
  type              = "ingress"
  from_port         = 27016
  to_port           = 27019
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.mongodb.id
}

resource "aws_security_group_rule" "self_http" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.mongodb.id
}

resource "aws_security_group_rule" "self_https" {
  type              = "ingress"
  from_port         = 8443
  to_port           = 8443
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.mongodb.id
}

resource "aws_security_group_rule" "self_queryable_snapshot" {
  type              = "ingress"
  from_port         = 25999
  to_port           = 27719
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.mongodb.id
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ip_whitelist
  security_group_id = aws_security_group.mongodb.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mongodb.id
}

resource "aws_security_group_rule" "mongod" {
  type              = "ingress"
  from_port         = 27016
  to_port           = 27019
  protocol          = "tcp"
  cidr_blocks       = var.ip_whitelist
  security_group_id = aws_security_group.mongodb.id
}

resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = concat(var.ip_whitelist, [data.aws_vpc.default.cidr_block])
  security_group_id = aws_security_group.mongodb.id
}

resource "aws_security_group_rule" "https" {
  type              = "ingress"
  from_port         = 8443
  to_port           = 8443
  protocol          = "tcp"
  cidr_blocks       = concat(var.ip_whitelist, [data.aws_vpc.default.cidr_block])
  security_group_id = aws_security_group.mongodb.id
}

resource "aws_security_group_rule" "queryable_snapshot" {
  type              = "ingress"
  from_port         = 25999
  to_port           = 27719
  protocol          = "tcp"
  cidr_blocks       = concat(var.ip_whitelist, [data.aws_vpc.default.cidr_block])
  security_group_id = aws_security_group.mongodb.id
}

// --------- EC2 INSTANCES ---------

resource "aws_instance" "node" {
  for_each = local.nodes

  ami                    = data.aws_ami.amzn2.id
  instance_type          = each.value["instance_type"]
  key_name               = var.ssh_key_name
  subnet_id              = element(data.aws_subnets.default.ids, each.value["idx"] % length(data.aws_subnets.default))
  vpc_security_group_ids = [aws_security_group.mongodb.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = each.value["root_volume_size"]
  }

  dynamic "ebs_block_device" {
    for_each = each.value["data_volume_size"] != null ? [each.value["data_volume_size"]] : []
    content {
      device_name = "/dev/sdb"
      volume_size = ebs_block_device.value
    }
  }

  tags = merge(
    {
      "Name" = each.value["name"]
    },
    var.tags
  )

  user_data = data.template_cloudinit_config.base[each.key].rendered
}

// --------- ROUTE 53 ----------

resource "aws_route53_record" "nodes" {
  for_each = local.nodes

  zone_id = var.zone_id
  name    = "${each.value["name"]}.${var.zone_domain}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.node[each.key].public_ip]
}

resource "aws_route53_record" "nlb" {
  count   = var.mms_load_balancer ? 1 : 0
  zone_id = var.zone_id
  name    = "${var.name}-mms-lb.${var.zone_domain}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.main[0].dns_name]
}

// --------- NLB ----------

resource "aws_lb" "main" {
  count              = var.mms_load_balancer ? 1 : 0
  name               = "${var.name}-mms-lb"
  internal           = false
  load_balancer_type = "network"
  subnets            = data.aws_subnets.default.ids

  tags = var.tags
}

module "routes" {
  for_each = var.mms_load_balancer ? {
    http  = { from = 8080, to = 80 }
    https = { from = 8443, to = 443 }
  } : {}
  source = "./modules/load-balancer"

  instance_ids      = local.webapp_instance_ids
  load_balancer_arn = aws_lb.main[0].arn
  name              = var.name
  tags              = var.tags
  internal_port     = each.value["from"]
  public_port       = each.value["to"]
  vpc_id            = data.aws_vpc.default.id
}

// --------- TEMPLATES ---------

resource "local_file" "install_agent_script" {
  content = templatefile("${path.module}/templates/install_agent.sh", {
    mmsGroupId = var.agent_group_id
    mmsApiKey  = var.agent_api_key
    mmsBaseUrl = var.agent_base_url
    agentRpm   = var.agent_rpm
  })
  filename = "${path.module}/generated/install_agent.sh"
}

resource "local_file" "etc_hosts" {
  content = templatefile("${path.module}/templates/init_etc_hosts.sh", {
    hosts = [
      for k, v in local.nodes : {
        fqdn = v["fqdn"],
        ip   = aws_instance.node[k].private_ip
      }
    ]
  })
  filename = "${path.module}/generated/init_etc_hosts.sh"
}

resource "local_file" "ansible_inventory" {
  content = yamlencode({
    all = {
      hosts = {
        for n in local.nodes_array : n["short_name"] => {
          ansible_host = n["fqdn"]
          mms_project = n["mms_project"]
          #          private_ip   = aws_instance.node[n["short_name"]].private_ip
        }
      }
      children = {
        for group in local.groups : group  => {
          hosts = {for n in local.nodes_array : n["short_name"] => {} if contains(n["groups"], group)}
        }
      }
    }
  })
  filename = "${path.module}/generated/inventory.yaml"
}

resource "local_file" "ansible_variable" {
  content = yamlencode({
    mms_central_host = var.mms_load_balancer ? aws_route53_record.nlb[0].fqdn : length(local.webapp_nodes_array) > 0 ? local.webapp_nodes_array[0]["fqdn"] : "N/A"
    mms_load_balanced = var.mms_load_balancer
  })
  filename = "${path.module}/generated/group_vars/all.yml"
}

// --------- CERTIFICATES ---------

module "https_cert" {
  source   = "./modules/tls-certs"
  for_each = local.webapp_nodes

  ca_cert_pem         = "./certs/ca.crt"
  ca_private_key_pem  = "./certs/ca.key"
  common_name         = var.mms_load_balancer ? aws_route53_record.nlb[0].fqdn : each.value["fqdn"]
  organization        = "MongoDB"
  organizational_unit = "PS"
  dns_names           = concat(var.mms_load_balancer ? [aws_route53_record.nlb[0].fqdn] : [], [each.value["fqdn"]])
  allowed_uses        = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]
}

module "server_auth_cert" {
  source   = "./modules/tls-certs"
  for_each = local.nodes

  ca_cert_pem         = "./certs/ca.crt"
  ca_private_key_pem  = "./certs/ca.key"
  common_name         = each.value["fqdn"]
  organization        = "MongoDB"
  organizational_unit = "PS"
  dns_names           = [each.value["fqdn"]]
  allowed_uses        = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]
}

module "client_auth_cert" {
  source   = "./modules/tls-certs"
  for_each = local.nodes

  ca_cert_pem         = "./certs/ca.crt"
  ca_private_key_pem  = "./certs/ca.key"
  common_name         = each.value["fqdn"]
  organization        = "MongoDB"
  organizational_unit = "PS"
  dns_names           = [each.value["fqdn"]]
  allowed_uses        = [
    "key_encipherment",
    "digital_signature",
    "client_auth"
  ]
}

module "combined_auth_cert" {
  for_each = local.nodes

  source              = "./modules/tls-certs"
  ca_cert_pem         = "./certs/ca.crt"
  ca_private_key_pem  = "./certs/ca.key"
  common_name         = each.value["fqdn"]
  organization        = "MongoDB"
  organizational_unit = "PS"
  dns_names           = [each.value["fqdn"]]
  allowed_uses        = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth"
  ]
}

module "client_user_cert" {
  source              = "./modules/tls-certs"
  ca_cert_pem         = "./certs/ca.crt"
  ca_private_key_pem  = "./certs/ca.key"
  common_name         = "mongoadmin"
  organization        = "MongoDB"
  organizational_unit = "PS"
  allowed_uses        = [
    "key_encipherment",
    "digital_signature",
    "client_auth"
  ]
}

// --------- FILES ---------

resource "local_file" "https_cert" {
  for_each = local.webapp_nodes

  content  = module.https_cert[each.key].cert_pem
  filename = "${path.module}/generated/certs/${each.key}-https.pem"
}

resource "local_file" "server_auth_cert" {
  for_each = local.nodes

  content  = module.server_auth_cert[each.key].cert_pem
  filename = "${path.module}/generated/certs/${each.key}-server.pem"
}

resource "local_file" "client_auth_cert" {
  for_each = local.nodes

  content  = module.client_auth_cert[each.key].cert_pem
  filename = "${path.module}/generated/certs/${each.key}-client.pem"
}

resource "local_file" "combined_auth_cert" {
  for_each = local.nodes

  content  = module.combined_auth_cert[each.key].cert_pem
  filename = "${path.module}/generated/certs/${each.key}-combined.pem"
}

resource "local_file" "client_user" {
  for_each = local.nodes

  content  = module.client_user_cert.cert_pem
  filename = "${path.module}/generated/certs/user.pem"
}
