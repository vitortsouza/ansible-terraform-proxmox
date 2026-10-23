resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.vm_name
  node_name = var.target_node
  vm_id     = var.vmid

  # hardware
  agent {
    enabled = true
  }

  bios = "seabios"

  cpu {
    cores   = var.cores
    sockets = var.sockets
    type    = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.memory
  }

  # rede
  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  # disco SCSI com import da imagem
  scsi_hardware = "virtio-scsi-pci"

  disk {
    datastore_id       = var.storage
    file_id            = var.disk_image
    interface          = "scsi0"
    size               = var.disk_size
    iothread           = true
    discard            = "on"
  }

  # cloud-init (sem cdrom deprecated)
  initialization {
    datastore_id = var.cloudinit_storage

    user_account {
      username = var.ciuser
      keys     = [file(pathexpand(var.ssh_key_path))]
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  # boot order
  boot_order = ["scsi0"]

  # serial console
  serial_device {}

  vga {
    type = "serial0"
  }

  # lifecycle
  lifecycle {
    ignore_changes = [initialization]
  }
  
  timeout_create       = 1800
  timeout_start_vm     = 1800
  timeout_stop_vm      = 300
  timeout_shutdown_vm  = 1800
  timeout_reboot       = 1800
  timeout_migrate      = 1800
  timeout_move_disk    = 1800
}
