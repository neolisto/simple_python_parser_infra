resource "azurerm_application_insights" "function_app_ai" {
  name                = "${var.def_prefix}-function-app-ai"
  resource_group_name = azurerm_resource_group.function_app_rg.name
  location            = azurerm_resource_group.function_app_rg.location
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.function_app_law.id
}

