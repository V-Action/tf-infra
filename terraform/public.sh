#!/bin/bash

BACKEND_IP=$1  # O IP do backend será passado como argumento

if [ -z "$BACKEND_IP" ]; then
    echo "ERRO: Nenhum IP de backend fornecido!"
    exit 1
fi

echo "Usando o IP do backend: $BACKEND_IP"

echo "Atualizando pacotes..."
sudo apt update && sudo apt install -y nginx git openjdk-17-jdk

REPO_URL_FRONT="https://github.com/V-Action/front-end"
REPO_URL_BACK="https://github.com/V-Action/back-end"

TMP_DIR="/tmp/vaction"
TMP_FRONT="$TMP_DIR/front-end"
TMP_BACK="$TMP_DIR/back-end"

echo "Limpando diretório temporário..."
sudo rm -rf "$TMP_DIR"
sudo mkdir -p "$TMP_DIR"

echo "Clonando o repositório do front end..."
sudo git clone "$REPO_URL_FRONT" "$TMP_FRONT"

echo "Clonando o repositório do back end..."
sudo git clone "$REPO_URL_BACK" "$TMP_BACK"

# ======================== Configurando Backend ========================

echo "Iniciando backend..."
sudo nohup env IPV4_PRIVATE="$BACKEND_IP" SPRING_DATASOURCE_PASSWORD="123" SPRING_DATASOURCE_URL="jdbc:mysql://$BACKEND_IP:3306/Vaction" SPRING_DATASOURCE_USERNAME="vaction-admin" java -jar "$TMP_DIR/back-end/api.jar" > /var/log/api.log 2>&1 &
echo "Backend iniciado com sucesso."

# ======================== Configurando Frontend ========================
echo "Configurando o frontend..."
sudo rm -rf /var/www/html/*
sudo cp -r "$TMP_DIR/front-end" /var/www/html/

# ======================== Configurando Nginx ========================
sudo bash -c 'cat <<EOT > /etc/nginx/sites-available/myserver
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    root /var/www/html/front-end/html;
    index login.html;

    location /css/ {
        alias /var/www/html/front-end/css/;
    }
    location /js/ {
        alias /var/www/html/front-end/js/;
    }
    location /Assets/ {
        alias /var/www/html/front-end/Assets/;
    }

    # Proxy para API principal
    location /vaction/ {
        proxy_pass http://localhost:8080/vaction/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOT'

# Ativando a configuração do Nginx
sudo ln -sf /etc/nginx/sites-available/myserver /etc/nginx/sites-enabled/myserver
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl reload nginx
sudo systemctl restart nginx
echo "Nginx configurado com sucesso."

# ======================== Removendo Diretório Temporário ========================
echo "Removendo arquivos temporários..."
sudo rm -rf "$TMP_DIR"

echo "Instalação concluída!"