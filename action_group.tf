resource "azurerm_monitor_action_group" "function_app_action_group" {
  name                = "${var.def_prefix}-action-group"
  resource_group_name = azurerm_resource_group.function_app_rg.name
  short_name          = "funcapp-ag"

  email_receiver {
    name                    = "email-notification"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

