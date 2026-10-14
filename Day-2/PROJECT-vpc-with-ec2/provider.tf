terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_cli             = true
  storage_use_azuread = true
}
