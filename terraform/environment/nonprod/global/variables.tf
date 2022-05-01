variable "resource_group_name" {
  
  description = "Resource group name"

  type = string

}

variable "resource_group_location" {
  
    description = "Resource group location"
    type = string
 
}

variable "tags" {
  
  type = map(string)
}

# App Insight

variable "app_insight_name" {
  
  description = "Name of the Application Insight"
  type =  string

}

# Log Analytics

variable "analytics_name" {

    description = "Name of the Log Analytics"
    type = string
  
}

variable "analytics_sku" {

    description = "Name of the logical analytics sku"
    type = string
  
}

variable "server_name" {

    description = "Name of the server"
  
}

variable "database_name" {

    description = "db name"

    type =  string
  
}

/*
  
variable "Global_Key_Vault_Name" {

    description = "Key Valut Name"
   
    type = string
}

variable "Global_Key_Vault_RG" {

    description = "Resource group of key vault"
   
    type = string
}

variable "Key_Vault_Name" {

    description = "Key Vault Name"
    
    type = string
}

*/

variable "KEY_VAULT_NAME" {
  description = "(Required) Commmon Key Vault name"
  type        = string
}

variable "KEY_VAULT_RGNAME" {
  description = "(Required) Commmon Key Vault Resource group"
  type        = string
}

variable "keyvault_name" {
  description = "(Required) Prod Key Vault name"
  type        = string
}

variable "app_config_name" {

    description = "Name of App Configuration"

    type = string
  
}
