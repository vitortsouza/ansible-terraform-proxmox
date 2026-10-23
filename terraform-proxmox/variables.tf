variable "pm_api_url" {
  type    = string
  default = "https://pve-node01.example.com:8006/"
}

variable "pm_api_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Token da API. Prefira definir a variável de ambiente PROXMOX_VE_API_TOKEN."
}

variable "pm_tls_insecure" {
  type    = bool
  default = true
}

variable "pm_ssh_username" {
  type    = string
  default = "root"
}

variable "pm_ssh_private_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519"
}

variable "vm_name" {
  type    = string
  default = "vm-example"
}

variable "target_node" {
  type    = string
  default = "pve-node01"
}

variable "vmid" {
  type    = number
  default = 9100
}

variable "clone_from" {
  type    = string
  default = null
}

variable "cores" {
  type    = number
  default = 2
}

variable "sockets" {
  type    = number
  default = 1
}

variable "memory" {
  type    = number
  default = 2048
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "storage" {
  type    = string
  default = "local-lvm"
}

variable "disk_image" {
  type    = string
  default = "local:iso/ubuntu-24.04-server-cloudimg-amd64.img"
}

variable "disk_size" {
  type    = number
  default = 20
}

variable "cloudinit_storage" {
  type    = string
  default = "local-lvm"
}

variable "ciuser" {
  type    = string
  default = "ansible"
}

variable "ssh_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}
