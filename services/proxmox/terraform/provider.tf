terraform {
  required_providers {
    proxmox = {
      source  = "registry.terraform.io/bpg/proxmox"
      version = "0.82.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://pve.local/api2/json"
  insecure = true
  username = "terraform@pve"
  password = "password"

  ssh {
    agent = false
    username = "root"
    private_key = file("~/.ssh/id_rsa")
    # or use password authentication
    # password    = "your_password"
  }
}


# provider "proxmox" {
#   alias = "pve"
#   pm_api_url = "https://pve.local/api2/json"
#   pm_user = "terraform@pve"
#   pm_password = "password"
#   pm_tls_insecure = true
# }