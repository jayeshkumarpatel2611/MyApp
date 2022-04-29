resource "azurerm_application_insights" "app-Insights" {

    name = var.app_insight_name

    resource_group_name = var.resource_group_name

    location = var.resource_group_location

    application_type = "web"

    sampling_percentage = 0

    workspace_id = azurerm_log_analytics_workspace.log-analytics.id

    tags = var.tags

    lifecycle {
      
      ignore_changes = [ tags ]

    }
  
}

resource "azurerm_log_analytics_workspace" "log-analytics" {

    name = var.analytics_name
    location = var.resource_group_location
    resource_group_name = var.resource_group_name
    sku = var.analytics_sku
    retention_in_days = 30

    tags = var.tags

    lifecycle {
      
      ignore_changes = [ tags ]
    }
  
}