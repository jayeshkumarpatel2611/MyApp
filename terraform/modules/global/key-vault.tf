data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyvault" {

    name = var.Key_Vault_Name

    resource_group_name = var.resource_group_name

    location = var.resource_group_location

    tenant_id = data.azurerm_client_config.current.tenant_id

    sku_name = "standard"


    access_policy {

        tenant_id = data.azurerm_client_config.current.tenant_id

        object_id = data.azurerm_client_config.current.object_id

        secret_permissions = [ "get", "list", "set", "delete", "purge", "recover" ]

        key_permissions = [ "get", "list", "create", "delete" ]

        storage_permissions = [ "get", "list", "set", "delete" ]

    }

}