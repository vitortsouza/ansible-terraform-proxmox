output "vm_id" {
  value       = proxmox_virtual_environment_vm.vm.vm_id
  description = "ID da VM criada"
}

output "vm_name" {
  value       = proxmox_virtual_environment_vm.vm.name
  description = "Nome da VM"
}

output "node_name" {
  value       = proxmox_virtual_environment_vm.vm.node_name
  description = "Node do Proxmox"
}
