#
# This Terraform module is used to create a DNS record for a container app,
# it uses SSL certificates from a Key Vault.
#

#
# To get some properties of the Container App Environment, we need to use the azapi_resource data source:
#
data "azapi_resource" "contapp_environment_customDomainVerificationId" {
  resource_id = var.container_app_environment_id
  type        = "Microsoft.App/managedEnvironments@2022-11-01-preview"
  response_export_values = ["properties.customDomainConfiguration.customDomainVerificationId"]
}

data "azapi_resource" "contapp_environment_defaultDomain" {
  resource_id = var.container_app_environment_id
  type        = "Microsoft.App/managedEnvironments@2022-11-01-preview"
  response_export_values = ["properties.defaultDomain"]
}

data "azurerm_container_app_environment" "container_app_environment" {
  name                = var.container_app_environment_name
  resource_group_name = var.container_app_environment_resource_group
}

resource "azurerm_dns_a_record" "app_a_dns" {
  name                = "${var.app_dns_name}${var.environment_suffix}"
  zone_name           = var.dns_zone_name
  resource_group_name = var.domain_zone_resource_group_name
  ttl                 = 300
  records = [data.azurerm_container_app_environment.container_app_environment.static_ip_address]
}

resource "azurerm_dns_txt_record" "app_domain_txt_dns" {
  name                = "asuid.${var.app_dns_name}${var.environment_suffix}"
  zone_name           = var.dns_zone_name
  resource_group_name = var.domain_zone_resource_group_name
  ttl                 = 300
  record {
    value = data.azapi_resource.contapp_environment_customDomainVerificationId.output.properties.customDomainConfiguration.customDomainVerificationId
  }

  tags = {
    environment = var.environment_tag
    warning     = var.warning_tag
  }
}

resource "time_sleep" "wait_1m_after_dns_records_created" {
  depends_on = [
    azurerm_dns_txt_record.app_domain_txt_dns,
    azurerm_dns_a_record.app_a_dns,
  ]
  create_duration = "60s"
}


resource "azurerm_container_app_custom_domain" "custom_domain" {
  depends_on = [
    time_sleep.wait_1m_after_dns_records_created
  ]
  name                                     = "${azurerm_dns_a_record.app_a_dns.name}.${var.dns_zone_name}"
  container_app_id                         = var.container_app_id
  # Reference the KeyVault Certificate resource created via azapi_resource in ACE
  container_app_environment_certificate_id = var.ace_keyvault_linked_certificate_id
  certificate_binding_type                 = "SniEnabled"

  # Ignore periodical certificate updates
  lifecycle {
    ignore_changes = all
  }
}
