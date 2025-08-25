resource "azurerm_service_plan" "function_app_sp" {
  name                = "${var.def_prefix}-function-app-sp"
  resource_group_name = azurerm_resource_group.function_app_rg.name
  location            = azurerm_resource_group.function_app_rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}
