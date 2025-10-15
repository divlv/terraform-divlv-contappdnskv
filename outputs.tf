#
output "fqdn_of_application" {
  value       = "${var.app_dns_name}.${var.dns_zone_name}"
  description = "FQDN (Fully Qualified Domain Name) for application. E.g. myapp.example.com"
}
