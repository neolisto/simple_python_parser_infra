resource "azurerm_linux_function_app" "function_app" {
  name                        = "${var.def_prefix}-function-app"
  resource_group_name         = azurerm_resource_group.function_app_rg.name
  location                    = azurerm_resource_group.function_app_rg.location
  storage_account_name        = azurerm_storage_account.function_app_storage_account.name
  storage_account_access_key  = azurerm_storage_account.function_app_storage_account.primary_access_key
  service_plan_id             = azurerm_service_plan.function_app_sp.id
  functions_extension_version = "~4"

  app_settings = {
    "AzureWebJobsStorage"      = azurerm_storage_account.function_app_storage_account.primary_connection_string
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }

  site_config {
    application_stack {
      python_version = "3.10"
    }
  }

}
