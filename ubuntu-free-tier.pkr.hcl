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
  default = "t3.micro" # Capa Gratuita (Free Tier)
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

# 3. Bloque de Construcción con aprovisionamiento Inline
build {
  name    = "packer-build-unified"
  sources = ["source.amazon-ebs.ubuntu_free_tier"]

provisioner "shell" {
    inline = [
      "echo '=== 1. Actualizando repositorios del sistema ==='",
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",

      "echo '=== 2. Instalando dependencias y Node.js v20 ==='",
      "sudo apt-get install -y curl git",
      "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -",
      "sudo apt-get install -y nodejs",
      
      "echo '=== 3. Instalando PM2 globalmente ==='",
      "sudo npm install -y -g pm2",

      "echo '=== 4. Creando una aplicación Node.js de prueba ==='",
      "sudo mkdir -p /var/www/myapp",
      "sudo chown -R ubuntu:ubuntu /var/www/myapp",
      "cat <<'EOF' > /var/www/myapp/index.js",
const http = require('http');
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('¡Hola mundo desde Node.js detrás de Nginx!\n');
});
server.listen(3000, () => {
  console.log('Servidor corriendo en el puerto 3000');
});
EOF

      "echo '=== 5. Arrancando Node.js con PM2 y configurando persistencia ==='",
      "cd /var/www/myapp",
      "pm2 start index.js --name 'my-app'",
      # Esto genera la configuración de inicio para el usuario ubuntu
      "pm2 startup systemd -u ubuntu --hp /home/ubuntu",
      # Guardamos el estado actual de PM2 para que reviva al reiniciar la instancia
      "pm2 save",

      "echo '=== 6. Instalando Nginx ==='",
      "sudo apt-get install -y nginx",

      "echo '=== 7. Configurando proxy inverso en Nginx ==='",
      "sudo tee /etc/nginx/sites-available/default > /dev/null <<'EOF'",
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

      "echo '=== 8. Reiniciando y habilitando Nginx ==='",
      "sudo systemctl restart nginx",
      "sudo systemctl enable nginx",
      "echo '=== ¡Proceso finalizado con éxito! ==='"
    ]
  }
}