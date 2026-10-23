provider "proxmox" {
  endpoint  = var.pm_api_url
  api_token = var.pm_api_token
  insecure  = var.pm_tls_insecure

  ssh {
    username    = var.pm_ssh_username
    private_key = file(pathexpand(var.pm_ssh_private_key_path))
  }
}
