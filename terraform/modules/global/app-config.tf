resource "azurerm_app_configuration" "appconf" {

    name = var.app_config_name
    resource_group_name = var.resource_group_name
    location = var.resource_group_location
    sku = "standard"
    tags = var.tags

    lifecycle {
      
      ignore_changes = [ tags ]

    }
}