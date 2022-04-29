data "azurerm_key_vault" "globalkeyvault" {
  
  name = var.Global_Key_Vault_Name
  resource_group_name = var.Global_Key_Vault_RG

}

data "azurerm_key_vault_secret" "secret1" {

    name = "serverUsername"
    key_vault_id = data.azurerm_key_vault.globalkeyvault.id

}

data "azurerm_key_vault_secret" "secret2" {

    name = "serverPassword"
    key_vault_id = data.azurerm_key_vault.globalkeyvault.id
}

resource "azurerm_key_vault_secret" "workspaceName" {

    name = "workspaceName"

    value = var.analytics_name

    key_vault_id = data.azurerm_key_vault.globalkeyvault.id

    depends_on = [
      
      azurerm_log_analytics_workspace.log-analytics
    ]
  
}

resource "azurerm_key_vault_secret" "globalRGName" {

    name = "globalRGName"
    value = var.resource_group_name
    key_vault_id = data.azurerm_key_vault.globalkeyvault.id
  
}

resource "azurerm_key_vault_secret" "appConfigName" {

    name = "appConfigName"
    value = var.app_config_name
    key_vault_id = data.azurerm_key_vault.globalkeyvault.id
}

resource "azurerm_key_vault_secret" "KeyVaultName" {

    name = "KeyVaultName"

    value = var.Key_Vault_Name

    key_vault_id = data.azurerm_key_vault.globalkeyvault.id  
}

resource "azurerm_key_vault_secret" "globalSQLservername" {

    name = "globalSQLservername"

    value = var.server_name

    key_vault_id = data.azurerm_key_vault.globalkeyvault.id
  
}

resource "azurerm_key_vault_secret" "globalSQLDBname" {

    name = "globalSQLDBname"
    value = var.database_name

    key_vault_id = data.azurerm_key_vault.globalkeyvault.id
}