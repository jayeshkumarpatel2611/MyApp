terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.92.0"
    }
  }

      backend "azurerm" {
        resource_group_name  = "RG-MyApp"
        storage_account_name = "myappstorage26"
        container_name       = "tfstate"
        key                  = "terraform1.tfstate"
    }

}

provider "azurerm" {
  
  features {
    
  }
}