packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# 1. Variables globales
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

# 2. Definición del Origen (Base de la imagen)
source "amazon-ebs" "ubuntu_free_tier" {
  region        = var.aws_region
  instance_type = var.instance_type
  ami_name      = "ami-nodejs-nginx-unified-{{timestamp}}"
  ssh_username  = "ubuntu"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical
  }
}

# 3. Bloque de Construcción
build {
  name    = "packer-build-clean"
  sources = ["source.amazon-ebs.ubuntu_free_tier"]

  # Inyecta y ejecuta el script de configuración
  provisioner "shell" {
    script = "./setup.sh"
  }
}