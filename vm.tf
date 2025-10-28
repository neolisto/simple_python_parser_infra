# Virtual Network
resource "azurerm_virtual_network" "vm_vnet" {
  name                = "${var.def_prefix}-vm-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.function_app_rg.location
  resource_group_name = azurerm_resource_group.function_app_rg.name
}

# Subnet
resource "azurerm_subnet" "vm_subnet" {
  name                 = "${var.def_prefix}-vm-subnet"
  resource_group_name  = azurerm_resource_group.function_app_rg.name
  virtual_network_name = azurerm_virtual_network.vm_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "vm_public_ip" {
  name                = "${var.def_prefix}-vm-public-ip"
  location            = azurerm_resource_group.function_app_rg.location
  resource_group_name = azurerm_resource_group.function_app_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Security Group
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.def_prefix}-vm-nsg"
  location            = azurerm_resource_group.function_app_rg.location
  resource_group_name = azurerm_resource_group.function_app_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Interface
resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.def_prefix}-vm-nic"
  location            = azurerm_resource_group.function_app_rg.location
  resource_group_name = azurerm_resource_group.function_app_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "vm_nsg_association" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

# Ubuntu Virtual Machine
resource "azurerm_linux_virtual_machine" "ubuntu_vm" {
  name                = "${var.def_prefix}-ubuntu-vm"
  resource_group_name = azurerm_resource_group.function_app_rg.name
  location            = azurerm_resource_group.function_app_rg.location
  size                = "Standard_B1s"
  admin_username      = var.vm_admin_username

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.vm_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  disable_password_authentication = true
}

# Output VM Public IP
output "vm_public_ip_address" {
  value       = azurerm_public_ip.vm_public_ip.ip_address
  description = "The public IP address of the Ubuntu VM"
}

output "vm_ssh_command" {
  value       = "ssh ${var.vm_admin_username}@${azurerm_public_ip.vm_public_ip.ip_address}"
  description = "SSH command to connect to the VM"
}

