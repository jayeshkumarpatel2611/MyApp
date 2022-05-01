resource "azurerm_mssql_server" "sql-server" {

    name = var.server_name
    resource_group_name = var.resource_group_name
    location = var.resource_group_location
    version = "12.0"
    administrator_login = data.azurerm_key_vault_secret.secret1.value
    administrator_login_password = data.azurerm_key_vault_secret.secret2.value

    tags = var.tags

    lifecycle {
      
        ignore_changes = [
          tags
        ]

    }
  
}

resource "azurerm_mssql_database" "sql-database" {

    name = var.database_name

    server_id = azurerm_mssql_server.sql-server.id

    collation = "SQL_Latin1_General_CP1_CI_AS"

    license_type = "LicenseIncluded"

    max_size_gb = 1

    read_scale = false

    zone_redundant = false

    tags = var.tags

    lifecycle {

        ignore_changes = [
          
          tags

        ]

    }

}


resource "azurerm_mssql_firewall_rule" "sql-firewall" {

    name = "AzureServiceRule"

    server_id = azurerm_mssql_server.sql-server.id

    start_ip_address = "0.0.0.0"

    end_ip_address = "0.0.0.0"
  
}
