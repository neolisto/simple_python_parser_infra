# Install Azure Monitor Agent on VM
resource "azurerm_virtual_machine_extension" "azure_monitor_agent" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.ubuntu_vm.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
}

# Data Collection Endpoint
resource "azurerm_monitor_data_collection_endpoint" "vm_dce" {
  name                = "${var.def_prefix}-vm-dce"
  resource_group_name = azurerm_resource_group.function_app_rg.name
  location            = azurerm_resource_group.function_app_rg.location
  kind                = "Linux"
}

# Data Collection Rule for syslog (auth logs)
resource "azurerm_monitor_data_collection_rule" "vm_dcr" {
  name                        = "${var.def_prefix}-vm-dcr"
  resource_group_name         = azurerm_resource_group.function_app_rg.name
  location                    = azurerm_resource_group.function_app_rg.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.vm_dce.id

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.function_app_law.id
      name                  = "law-destination"
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["law-destination"]
  }

  data_sources {
    syslog {
      facility_names = ["auth", "authpriv"]
      log_levels     = ["Debug", "Info", "Notice", "Warning", "Error", "Critical", "Alert", "Emergency"]
      name           = "syslog-auth"
      streams        = ["Microsoft-Syslog"]
    }
  }
}

# Associate Data Collection Rule with VM
resource "azurerm_monitor_data_collection_rule_association" "vm_dcr_association" {
  name                    = "${var.def_prefix}-vm-dcr-association"
  target_resource_id      = azurerm_linux_virtual_machine.ubuntu_vm.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_dcr.id
  depends_on = [
    azurerm_virtual_machine_extension.azure_monitor_agent
  ]
}

# Grant VM's managed identity permission to send data to DCR
resource "azurerm_role_assignment" "vm_monitoring_metrics_publisher" {
  count                = length(azurerm_linux_virtual_machine.ubuntu_vm.identity) > 0 ? 1 : 0
  scope                = azurerm_monitor_data_collection_rule.vm_dcr.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_linux_virtual_machine.ubuntu_vm.identity[0].principal_id
  
  depends_on = [
    azurerm_linux_virtual_machine.ubuntu_vm
  ]
}


# Scheduled Query Alert Rule for SSH Login Detection
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "ssh_login_alert" {
  name                = "${var.def_prefix}-ssh-login-alert"
  resource_group_name = azurerm_resource_group.function_app_rg.name
  location            = azurerm_resource_group.function_app_rg.location

  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"
  scopes               = [azurerm_log_analytics_workspace.function_app_law.id]
  severity             = 2

  criteria {
    query                   = <<-QUERY
      Syslog
      | where Computer == "${azurerm_linux_virtual_machine.ubuntu_vm.name}"
      | where Facility == "auth" or Facility == "authpriv"
      | where SyslogMessage contains "Accepted publickey" or SyslogMessage contains "Accepted password" or SyslogMessage contains "session opened"
      | where SyslogMessage contains "ssh" or ProcessName == "sshd"
      | project TimeGenerated, Computer, SyslogMessage, ProcessName, HostIP
    QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  auto_mitigation_enabled          = false
  workspace_alerts_storage_enabled = false
  description                      = "Alert triggered when someone logs in to the VM via SSH"
  display_name                     = "SSH Login Detected"
  enabled                          = true
  skip_query_validation            = false

  action {
    action_groups = [azurerm_monitor_action_group.function_app_action_group.id]
  }
}

