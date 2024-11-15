output "public_ip_lb" {
  value = azurerm_public_ip.example_lb_public_ip.ip_address
}

output "vm_private_ips" {
  value = azurerm_network_interface.example_nic[*].private_ip_address
}