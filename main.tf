# Provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

# Resource Group
resource "azurerm_resource_group" "example_rg" {
  name     = "example-resource-group"
  location = "Canada Central"
}

# Availability Set
resource "azurerm_availability_set" "example_avset" {
  name                         = "example-availability-set"
  location                     = azurerm_resource_group.example_rg.location
  resource_group_name          = azurerm_resource_group.example_rg.name
  managed                      = true
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
}

# Virtual Network
resource "azurerm_virtual_network" "example_vnet" {
  name                = "example-vnet"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "example_subnet" {
  name                 = "example_subnet"
  resource_group_name  = azurerm_resource_group.example_rg.name
  virtual_network_name = azurerm_virtual_network.example_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP for Load Balancer
resource "azurerm_public_ip" "example_lb_public_ip" {
  name                = "example_lb_public_ip"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name
  allocation_method   = "Static"
  sku = "Standard"
}

# Load Balancer
resource "azurerm_lb" "example_lb" {
  name                = "example-loadbalancer"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.example_lb_public_ip.id
  }
}

# Backend Address Pool for Load Balancer
resource "azurerm_lb_backend_address_pool" "example_backend_pool" {
  loadbalancer_id = azurerm_lb.example_lb.id
  name            = "backend-pool"
}

# Load Balancer Probe
resource "azurerm_lb_probe" "http_probe" {
  name                = "http-probe"
  loadbalancer_id     = azurerm_lb.example_lb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Load Balancer Probe for ssh
resource "azurerm_lb_probe" "ssh_probe" {
  name                = "ssh-probe"
  loadbalancer_id     = azurerm_lb.example_lb.id
  protocol            = "Tcp"
  port                = 22
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Load Balancer Rule (using backend_address_pool_ids)
resource "azurerm_lb_rule" "example_lb_rule" {
  loadbalancer_id                = azurerm_lb.example_lb.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.example_backend_pool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
}
# Load Balancer Rule (for ssh)
resource "azurerm_lb_rule" "ssh_lb_rule" {
  loadbalancer_id                = azurerm_lb.example_lb.id
  name                           = "ssh-rule"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.example_backend_pool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.env_name}-nsg"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name

  security_rule {
    name                       = "Allow_SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_HTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Interface
resource "azurerm_network_interface" "example_nic" {
  count               = 2
  name                = "example-nic-${count.index}"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Associate each NIC with the Load Balancer Backend Pool (with ip_configuration_name)
resource "azurerm_network_interface_backend_address_pool_association" "example_lb_nic_association" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.example_nic[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.example_backend_pool.id
  }

# Associate each NIC with the NSG
resource "azurerm_network_interface_security_group_association" "example" {
  count = 2
  network_interface_id      = azurerm_network_interface.example_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Virtual Machines
resource "azurerm_linux_virtual_machine" "vm" {
  count                 = 2
  name                  = "${var.env_name}-vm-${count.index}"
  location              = azurerm_resource_group.example_rg.location
  resource_group_name   = azurerm_resource_group.example_rg.name
  size                  = "Standard_B1s"
  availability_set_id   = azurerm_availability_set.example_avset.id
  network_interface_ids = [azurerm_network_interface.example_nic[count.index].id]
  disable_password_authentication = true

  admin_username = "adminuser"

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
