
resource "azurerm_storage_account" "function_app_storage_account" {
  name                     = "${var.def_prefix}funcappsa"
  resource_group_name      = azurerm_resource_group.function_app_rg.name
  location                 = azurerm_resource_group.function_app_rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}
