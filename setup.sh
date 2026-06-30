#!/bin/bash
set -e # Detiene el script si algún comando falla

echo "=== 1. Actualizando repositorios del sistema ==="
sudo apt-get update -y
sudo apt-get upgrade -y

echo "=== 2. Instalando dependencias y Node.js v20 ==="
sudo apt-get install -y curl git
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

echo "=== 3. Instalando PM2 globalmente ==="
sudo npm install -g pm2

echo "=== 4. Creando una aplicación Node.js de prueba ==="
sudo mkdir -p /var/www/myapp
sudo chown -R ubuntu:ubuntu /var/www/myapp

cat << 'EOF' > /var/www/myapp/index.js
const http = require('http');
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('¡Hola mundo desde Node.js detrás de Nginx!\n');
});
server.listen(3000, () => {
  console.log('Servidor corriendo en el puerto 3000');
});
EOF

echo "=== 5. Arrancando Node.js con PM2 y configurando persistencia ==="
cd /var/www/myapp
pm2 start index.js --name "my-app"
# Configura PM2 para que inicie con el sistema usando el usuario 'ubuntu'
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu
pm2 save

echo "=== 6. Instalando Nginx ==="
sudo apt-get install -y nginx

echo "=== 7. Configurando proxy inverso en Nginx ==="
sudo tee /etc/nginx/sites-available/default > /dev/null << 'EOF'
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

echo "=== 8. Reiniciando y habilitando Nginx ==="
sudo systemctl restart nginx
sudo systemctl enable nginx

echo "=== ¡Proceso finalizado con éxito! ==="