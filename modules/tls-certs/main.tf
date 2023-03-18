resource "tls_private_key" "main" {
  algorithm   = "RSA"
  rsa_bits    = 4096
}

resource "tls_cert_request" "main" {
  #key_algorithm   = "RSA"
  private_key_pem = tls_private_key.main.private_key_pem
  dns_names = var.dns_names

  subject {
    common_name         = var.common_name
    organizational_unit = var.organizational_unit
    organization        = var.organization
  }
}

resource "tls_locally_signed_cert" "main" {
  cert_request_pem   = tls_cert_request.main.cert_request_pem
  #ca_key_algorithm   = "RSA"
  ca_private_key_pem = file(var.ca_private_key_pem)
  ca_cert_pem        = file(var.ca_cert_pem)

  validity_period_hours = var.validity_period_hours

  allowed_uses = var.allowed_uses
}