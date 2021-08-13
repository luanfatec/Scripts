#!/bin/bash

#Config project
projectName=""
host=""
projectNameApacheconfig=""
passShell=""

#DdConfig
dbconnection="mysql"
dbhost=""
dbport="3306"
dbname=""
dbuser=""
dbpass=""


function dependencias() {
    clear
    echo "$passShell" |sudo -S apt install software-properties-common
    clear
    sleep 0.5
    echo "$passShell" |sudo -S add-apt-repository ppa:ondrej/php
    clear
    sleep 0.5

    # Array de dependências.
    # Para que seja instalado novas dependências, é preciso inserir o nome no array.
    # Tenha certeza que a versão inserida está disponivel nos repositórios do Debian.
	PROGRAMA=(
        "php7.4" "php7.4-gd" "php7.4-mbstring" "php7.4-xml"
        "apache2" "libapache2-mod-php7.4" "mysql-server" "php7.4-mysql openssl ssl-cert"

    )
        
    for prog_inst in "${PROGRAMA[@]}";do
        if ! hash "$prog_inst" 2>/dev/null;then
            echo "$passShell" |sudo -S apt-get update && sleep 3 && sudo apt-get install -y $prog_inst && exit
            sleep 0.5
        else
            sleep 0.5
            continue
        fi
    done
    clear

}

function installComposer() {
    clear
    # Download e Instalação do composer
    # Versão mais recente.
    echo "$passShell" |sudo -S curl -sS https://getcomposer.org/installer | php
    echo "$passShell" |sudo -S sudo mv composer.phar /usr/local/bin/composer
    echo "$passShell" |sudo -S sudo chmod +x /usr/local/bin/composer
}

function downloadAndInstallLaravel() {
    clear
    cd /var/www
    # Iniciando uma instância do láravel.
    # Download Laravel.
    echo "$passShell" |sudo -S composer create-project --prefer-dist laravel/laravel $projectName
    #
    # Permissões necessárias para que o láravel possa rodar sem nenhum problema...
    # echo "$passShell" |sudo -S chgrp -R www-data /var/www/$projectName
    echo "$passShell" |sudo -S chown -R www-data.www-data /var/www/$projectName
    echo "$passShell" |sudo -S chmod -R 755 /var/www/$projectName
    echo "$passShell" |sudo -S chmod -R 777 /var/www/$projectName/storage
   
    # Inserção das configurações do apache.
    # As configurações do apache serão feitas automaticamente,
    # configurações antigas ou padrões serão desabilitadas.
    echo -e "$passShell" |sudo -S echo -e "<VirtualHost *:80>\n\
        ServerAdmin webmaster@$projectName.edu.br\n\
        ServerName www.$projectName.edu.br\n\
        DocumentRoot /var/www/$projectName/public\n\
        ErrorLog /var/log/apache2/error_$projectName.log\n\
        LogLevel warn\n\
        CustomLog /var/log/apache2/access_$projectName.log combined\n\
    </VirtualHost>" > /etc/apache2/sites-available/$projectNameApacheconfig.conf
    echo "$passShell" |sudo -S a2dissite 000-default.conf 
    echo "$passShell" |sudo -S a2ensite $projectNameApacheconfig.conf
    echo "$passShell" |sudo -S a2enmod rewrite 
    echo "$passShell" |sudo -S service apache2 restart 
}

# alterando as configurações do arquido Dotenv.
# Se necessário alterar mais alguma configuração, basta inserir uma variável no inicio do arquivo,
# e duplicar uma linha e alterar os valores a serem substituidos no Dotenv.
function createEnvironmentSettings() {
    clear
    cd /var/www/$projectName
    echo "$passShell" |sudo -S mv .env.example .env 
    echo "$passShell" |sudo -S php artisan key:generate
    echo "$passShell" |sudo -S sed -i "s/DB_CONNECTION=mysql/DB_CONNECTION=$dbconnection/g" .env 
    echo "$passShell" |sudo -S sed -i "s/DB_HOST=127.0.0.1/DB_HOST=$dbhost/g" .env 
    echo "$passShell" |sudo -S sed -i "s/DB_PORT=3306/DB_PORT=$dbport/g" .env 
    echo "$passShell" |sudo -S sed -i "s/DB_DATABASE=laravel/DB_DATABASE=$dbname/g" .env 
    echo "$passShell" |sudo -S sed -i "s/DB_USERNAME=laravel/DB_USERNAME=$dbuser/g" .env 
    echo "$passShell" |sudo -S sed -i "s/DB_PASSWORD=secret/DB_PASSWORD=$dbpass/g" .env
}

# Iniciando uma db para a aplicação.
# Se acaso não for necessário, basta desconsiderar a opção.
# Junto ao banco de dados, será criado um usuário junto.
function createMysqlUserAndDatabase() {
    clear
    echo "$passShell" |sudo -S mysql -u root -e "CREATE DATABASE $dbname"
    echo "$passShell" |sudo -S mysql -u root -e "CREATE USER '$dbuser'@'$dbhost' IDENTIFIED BY '$dbpass'"
    echo "$passShell" |sudo -S mysql -u root -e "GRANT ALL ON laravel.* to '$dbuser'@'$dbhost'"
    echo "$passShell" |sudo -S mysql -u root -e "FLUSH PRIVILEGES"
}

# Menu.
panel() {
    clear
    echo -e "\nEscolha uma opção: \n"
    echo -ne "\n1) Instalar depedências\n2) Instalar composer\n3) Instalar uma instância do laravel\n4) Configurar ambiente\n5) Criar banco de dado e usuário\n\nDigite a opção: "; read OPTION
}

panel

# Case de lógica.
# As opções inseridas acima no Menu, serão comparadas no case abaixo.
case $OPTION in
    1) dependencias
    cd /var/www/html
        ./start-laravel.sh;;
    2) installComposer 
    cd /var/www/html
        ./start-laravel.sh;;
    3) downloadAndInstallLaravel 
    cd /var/www/html
        ./start-laravel.sh;;
    4) createEnvironmentSettings 
    cd /var/www/html
        ./start-laravel.sh;;
    5) createMysqlUserAndDatabase 
    cd /var/www/html
        ./start-laravel.sh;;
    *) cd /var/www/html
        ./start-laravel.sh ;;
esac
