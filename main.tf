terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "neolisto_test_org"

    workspaces {
      prefix = "simple_python_parser_infra"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.41.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}
