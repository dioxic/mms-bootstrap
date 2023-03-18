variable "dns_names" {
  type = list(string)
  description = "list of DNS names"
  default = []
}

variable "ca_private_key_pem" {}

variable "ca_cert_pem" {}

variable "common_name" {}

variable "organizational_unit" {
  default = "PS"
}

variable "organization" {
  default = "MongoDB"
}

variable "validity_period_hours" {
  type    = number
  default = 720
}

variable "allowed_uses" {
  type    = list(string)
  default = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth"
  ]
}