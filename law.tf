resource "azurerm_log_analytics_workspace" "function_app_law" {
  name                = "${var.def_prefix}-initial-law"
  resource_group_name = azurerm_resource_group.function_app_rg.name
  location            = azurerm_resource_group.function_app_rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
