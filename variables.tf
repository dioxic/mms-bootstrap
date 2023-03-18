variable "ssh_key_name" {
  type = string
}

variable "ssh_key_file" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "ssh_username" {
  type    = string
  default = "ec2-user"
}

variable "agent_rpm" {
  type = string
}

variable "agent_group_id" {
  type = string
}

variable "agent_api_key" {
  type = string
}

variable "agent_base_url" {
  type = string
}

variable "tags" {
  description = "Optional map of tags to set on resources, defaults to empty map."
  type        = map(string)
  default     = {}
}

variable "name" {
  type = string
}

variable "ip_whitelist" {
  type = list(string)
}

variable "zone_id" {
  type = string
}

variable "zone_domain" {
  type = string
}

variable "mms_load_balancer" {
  type = bool
  default = false
}

variable "nodes" {
  type = list(object({
    name             = string,
    groups           = list(string),
    mms_project      = optional(string),
    instance_type    = string,
    root_volume_size = optional(number, 8),
    data_volume_size = optional(number),
    count            = number
  }))
}