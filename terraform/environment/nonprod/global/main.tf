terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "POH"
    storage_account_name = "sunriseappeastus"
    container_name       = "sunriseprodtfstate"
    #backend will retrieve the key from yml file.
  }
}

provider "azurerm" {
  features {}
}

module "global" {
  
  source = "../../../modules/global"


resource_group_name = var.resource_group_name
resource_group_location = var.resource_group_location
tags = var.tags

app_insight_name = var.app_insight_name
analytics_name = var.analytics_name
analytics_sku = var.analytics_sku

Global_Key_Vault_Name = var.Global_Key_Vault_Name
Global_Key_Vault_RG = var.globalRGName
Key_Vault_Name = var.Key_Vault_Name

server_name = var.server_name
database_name = var.database_name

app_config_name = var.app_config_name

}
