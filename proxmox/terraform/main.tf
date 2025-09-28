resource "proxmox_virtual_environment_vm" "ubuntu" {
  name        = "terraform-ubuntu"
  description = "Ubuntu VM created with Terraform"
  tags        = ["terraform", "ubuntu"]

  node_name = "pve"
  vm_id     = 120

  agent {
    enabled = true
  }
  stop_on_destroy = true

  startup {
    order      = "3"
    up_delay   = "30"
    down_delay = "30"
  }

  cpu {
    cores   = 2
    sockets = 1
    type    = "x86-64-v2-AES"
  }

  memory {
    dedicated = 2048
    floating  = 2048
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
    size         = 20
  }


  network_device {
    bridge = "vmbr0"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.68.15/24"
        gateway = "192.168.68.11"
      }
    }

    user_account {
      # do not use this in production, configure your own ssh key instead!
      username = "admin"
      password = "password"
    }
  }
}

# resource "proxmox_virtual_environment_download_file" "debian_iso" {
#   node_name    = "pve"
#   url          = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.1.0-amd64-netinst.iso"
#   datastore_id = "local"
#   content_type = "iso"
#   file_name    = "debian-13.1.0-amd64-netinst.iso"
# }

resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve"
  file_name    = "jammy-server-cloudimg-amd64.img"

  url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}