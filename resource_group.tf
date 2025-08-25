resource "azurerm_resource_group" "function_app_rg" {
  name     = "${var.def_prefix}-function-app-rg"
  location = "West Europe"
}