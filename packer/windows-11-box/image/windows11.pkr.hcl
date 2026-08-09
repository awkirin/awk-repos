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

source "virtualbox-iso" "windows11" {
  vm_name       = "windows-11-25h2-pro-ru"
  guest_os_type = "Windows11_64"
  iso_url       = "iso/Win11_25H2_Russian_x64.iso"
  iso_checksum  = "sha256:e1efe78f43a1e059912fc600bbcecac349a33f8bb7b1562b0a2966c31e9674bc"

  communicator   = "winrm"
  winrm_username = "vagrant"
  winrm_password = "vagrant"
  winrm_timeout  = "45m"

  cpus      = 4
  memory    = 16384
  disk_size = 81920

  firmware             = "efi"
  iso_interface        = "sata"
  hard_drive_interface = "sata"
  sata_port_count      = 4
  guest_additions_mode = "attach"
  shutdown_timeout     = "30m"
  output_directory     = "build/virtualbox"

  boot_wait = "5s"
  boot_command = [
    "<enter><wait5>"
  ]

  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--tpm-type", "2.0"],
    ["storageattach", "{{.Name}}", "--storagectl", "SATA", "--port", "2", "--device", "0", "--type", "dvddrive", "--medium", "build/answer-files.iso"]
  ]

  shutdown_command = "powershell.exe -NoProfile -Command \"Start-ScheduledTask -TaskName PackerSysprep\""
}

build {
  sources = ["source.virtualbox-iso.windows11"]

  provisioner "file" {
    source      = "image/scripts/enable-winrm.ps1"
    destination = "C:/Windows/Temp/enable-winrm.ps1"
  }

  provisioner "powershell" {
    scripts = ["image/scripts/install-guest-additions.ps1"]
  }

  provisioner "windows-restart" {
    restart_timeout = "15m"
  }

  provisioner "powershell" {
    scripts = [
      "image/scripts/prepare-sysprep.ps1",
      "image/scripts/verify.ps1"
    ]
  }

  post-processor "vagrant" {
    output               = "output/windows11-25h2-pro-ru-virtualbox.box"
    vagrantfile_template = "image/vagrant/Vagrantfile.template"
  }
}
