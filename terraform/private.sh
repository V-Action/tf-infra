#!/bin/bash

check_mysql() {
    if ! which mysql > /dev/null 2>&1; then
        echo "MySQL não está instalado. Instalando MySQL Server 8.0..."
        install_mysql
    else
        echo "MySQL já está instalado."
        configure_mysql
    fi
}

install_mysql() {
    echo "Instalando MySQL Server 8.0..."
    sudo apt update
    sudo apt install -y mysql-server
    sudo systemctl start mysql
    sudo systemctl enable mysql
    echo "MySQL Server instalado e iniciado."
    configure_mysql
}

configure_mysql() {
    echo "Configurando MySQL para aceitar conexões externas..."
    
    MYSQL_CONFIG="/etc/mysql/mysql.conf.d/mysqld.cnf"

    # Alterando o bind-address para 0.0.0.0
    sudo sed -i "s/^bind-address\s*=.*/bind-address = 0.0.0.0/" "$MYSQL_CONFIG"

    echo "Reiniciando o MySQL para aplicar as mudanças..."
    sudo systemctl restart mysql
    
    create_db_user
}

create_db_user() {
    DB_USER="vaction-admin"
    DB_PASS="123"

    echo "Criando o usuário '$DB_USER' no MySQL..."
    sudo mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO '$DB_USER'@'%' WITH GRANT OPTION;"
    sudo mysql -e "FLUSH PRIVILEGES;"

    echo "Usuário '$DB_USER' criado com sucesso."
    setup_database
}

setup_database() {
  DB_DIR="/tmp/database"
  echo "Executando scripts SQL para configurar o banco de dados..."
  for script in criacao-tabelas.sql views-e-procedures.sql popular-dados.sql; do
    if [ -f "$DB_DIR/$script" ]; then
      echo "Executando $script..."
      sudo mysql < "$DB_DIR/$script"
    else
      echo "Arquivo $script não encontrado. Pulando..."
    fi
  done

  echo "Banco de dados configurado com sucesso."

  echo "Banco de dados configurado com sucesso."

  echo "Removendo repositório do diretório temporário..."
  rm -rf "$DB_REPO_DIR"
}

# Executar verificações e configurações
check_mysql