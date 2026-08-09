packer {
  required_version = ">= 1.14.0"

  required_plugins {
    virtualbox = {
      source  = "github.com/hashicorp/virtualbox"
      version = "~> 1.1"
    }
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1.1"
    }
  }
}

variable "iso_path" {
  type    = string
  default = "Win11_25H2_Russian_x64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:e1efe78f43a1e059912fc600bbcecac349a33f8bb7b1562b0a2966c31e9674bc"
}

variable "edition_index" {
  type = number
}

variable "answer_iso_path" {
  type    = string
  default = ".generated/answer-files.iso"
}

locals {
  vm_name = "windows-11-25h2-pro-ru"
}

source "virtualbox-iso" "windows11" {
  vm_name       = local.vm_name
  guest_os_type = "Windows11_64"
  iso_url       = var.iso_path
  iso_checksum  = var.iso_checksum

  communicator   = "winrm"
  winrm_username = "vagrant"
  winrm_password = "vagrant"
  winrm_timeout  = "45m"

  cpus      = 6
  memory    = 16384
  disk_size = 81920

  firmware                  = "efi"
  iso_interface             = "sata"
  hard_drive_interface      = "sata"
  sata_port_count           = 4
  guest_additions_mode      = "attach"
  guest_additions_interface = "sata"
  shutdown_timeout          = "30m"
  output_directory          = "output-virtualbox"

  boot_wait = "5s"
  boot_command = [
    "<enter><wait5>"
  ]

  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--tpm-type", "2.0"],
    ["storageattach", "{{.Name}}", "--storagectl", "SATA", "--port", "2", "--device", "0", "--type", "dvddrive", "--medium", var.answer_iso_path]
  ]

  shutdown_command = "C:/Windows/System32/Sysprep/Sysprep.exe /generalize /oobe /shutdown /unattend:C:/Windows/Panther/SysprepUnattend.xml"
}

build {
  sources = ["source.virtualbox-iso.windows11"]

  provisioner "file" {
    source      = "scripts/enable-winrm.ps1"
    destination = "C:/Windows/Temp/enable-winrm.ps1"
  }

  provisioner "powershell" {
    scripts = [
      "scripts/install-guest-additions.ps1",
      "scripts/prepare-sysprep.ps1",
      "scripts/verify.ps1"
    ]
  }

  post-processor "vagrant" {
    output               = "output/windows11-25h2-pro-ru-virtualbox.box"
    vagrantfile_template = "vagrant/Vagrantfile.template"
  }
}
