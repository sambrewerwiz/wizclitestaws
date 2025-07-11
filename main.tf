provider "azurerm" {
  features {}
  subscription_id = "57538909-fbd0-4e2b-989d-c15c8a4d5303"
}

resource "azurerm_resource_group" "rg" {
  name     = "tf-devops-rg"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "tf-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "tf-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "tf-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowAllInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "tf-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "tf-ubuntu-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "tf-osdisk"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
  username   = "azureuser"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSLuWuBSsQF5Izo+WqT+Vyb0LNU1Ql9mUlsOuIHnDvnYlkW7ru9R3fbAUGMS0OV+PssLSmA6+cUsNn9sI8YE551cBkj5voz6Ya6VeknrX17hhbKrzQ1HVVHYvHnPmlhPS28hkcQDj2aytQNYFhrrsNezha0GaLXfEzVZHejBFhNBJS1WHs+SSY7nWFL41X1Rmob6rqB+UQ++FDw9w4dHfjFbq91CNQjuGuc5K+ecZ9fLuFbimWcy6UuHP6ldz5PSeRWpJMU7JWqZF8fPMTb+bD5FvgOHZlo1IlkouBE97S1Mvm+3NPPiURyWoJlS1TjN9ZlcSi9fRCZgQ/Ca81rz4h sam.brewer@M4DF7W7FR7"
}

  disable_password_authentication = true
}
