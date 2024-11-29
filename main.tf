provider "azurerm" {
  features {}

  subscription_id = "d62a7e90-f0c3-43c9-b445-646983f3e4c0"
  client_id       = "e804334b-2b61-43ec-8b1e-bd7357bcd279"
  client_secret   = "XXJ8Q~TjnWAdeLxX_C6XYPJ4kEHjqdqFuB-SydoM"
  tenant_id       = "1439bd4e-4816-4182-b8cb-50c06514ddda"
}

# Створення групи ресурсів
resource "azurerm_resource_group" "rg" {
  name     = "terrafrom-${var.env_name}-resource-group"
  location = "North Europe"
}

# Створення віртуальної мережі
resource "azurerm_virtual_network" "vnet" {
  name                = "terrafrom-${var.env_name}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# Створення підмережі 1
resource "azurerm_subnet" "subnet1" {
  name                 = "terrafrom-${var.env_name}-subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Створення підмережі 2
resource "azurerm_subnet" "subnet2" {
  name                 = "terrafrom-${var.env_name}-subnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Створення групи безпеки
resource "azurerm_network_security_group" "nsg" {
  name                = "terrafrom-${var.env_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # ssh 
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

# Асоціація підмережі 1 з групою безпеки
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association1" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Асоціація підмережі 2 з групою безпеки
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association2" {
  subnet_id                 = azurerm_subnet.subnet2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Налаштування публічної IP-адреси для обох машин
resource "azurerm_public_ip" "pip" {
  count               = 2
  name                = "terrafrom-${var.env_name}-pip-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Налаштування мережевого інтерфейсу для кожної машини
resource "azurerm_network_interface" "nic" {
  count               = 2
  name                = "terrafrom-${var.env_name}-nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet["subnet${count.index + 1}"].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[count.index].id
  }
}

# Створення віртуальних машин
resource "azurerm_linux_virtual_machine" "vm" {
  count                 = 2
  name                  = "terrafrom-lesson-vm-${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]

  # Указываем путь к приватному ключу
  disable_password_authentication = true
  admin_ssh_key {
    username   = "adminuser"  # Имя пользователя для подключения
    public_key = file("${path.module}/ssh/id.rsa.pub")  # Указываем путь к публичному ключу
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

output "public_ip_addresses" {
  value = azurerm_public_ip.pip[*].ip_address
}
