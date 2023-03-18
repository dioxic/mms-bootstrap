output "cert_pem" {
  value = join("",[tls_locally_signed_cert.main.cert_pem, tls_private_key.main.private_key_pem])
}

output "dns_names" {
  value = var.dns_names
}

output "common_name" {
  value = var.common_name
}

output "organization" {
  value = var.organization
}

output "organizational_unit" {
  value = var.organizational_unit
}