# Terraform authentication data
variable "subscription_id" {}
variable "client_id" {}
variable "tenant_id" {}
variable "client_secret" {}

variable "def_prefix" {
  type = string
}

variable "alert_email" {
  type        = string
  description = "Email address for alert notifications"
}

variable "vm_admin_username" {
  type        = string
  description = "Admin username for the Ubuntu VM"
  default     = "azureuser"
}

variable "vm_ssh_public_key" {
  type        = string
  description = "SSH public key for VM authentication"
}

