# Вихідні дані для публічних IP-адрес кожної віртуальної машини
output "public_ip_addresses" {
  description = "Public IP addresses of the virtual machines"
  value       = [for ip in azurerm_public_ip.pip : ip.ip_address]
}

# Вихідний файл інвентаря для Ansible
output "ansible_inventory" {
  description = "Ansible inventory file generated from Terraform outputs"
  value = join("\n", concat(
    ["---", "all:", "  hosts:"],
    [for index, ip in azurerm_public_ip.pip : join("\n", [
      "    vm-${index}:",
      "      ansible_host: ${ip.ip_address}",
      "      ansible_user: adminuser",
      "      ansible_ssh_pass: YourSecurePassword123!"
    ])]
  ))
}
