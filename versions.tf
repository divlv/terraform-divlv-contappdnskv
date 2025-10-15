terraform {
  required_version = ">= 1.10.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.99.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 2.3.0"
    }
  }
}
