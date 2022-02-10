#install-zbx6
#!/bin/bash
read -p "Digite a senha do banco de dados: " SENHA
read -p "Digite o IP do Zabbix Server: " SERVIDOR
read -p "Digite o Hostname do Zabbix : " HOSTNAME

wget https://repo.zabbix.com/zabbix/5.5/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.5-1+ubuntu20.04_all.deb
dpkg -i zabbix-release_5.5-1+ubuntu20.04_all.deb

bash mariadb*/setup_repository

apt update && apt upgrade -y

echo "

Instalando aplicações

"
apt install mariadb-server mariadb-client apache2 libapache2-mod-php php php-mysql php-cli php-pear php-gmp php-gd php-bcmath php-mbstring php-curl php-xml php-zip -y
apt install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent snmp snmp-mibs-downloader -y

a2enmod rewrite

sed -i 's/ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-available/security.conf
sed -i 's/ServerSignature On/ServerSignature Off/' /etc/apache2/conf-available/security.conf
sed -i "s@;date.timezone =@date.timezone = America/Sao_Paulo@g" /etc/php/7.4/apache2/php.ini

systemctl reload apache2
systemctl enable apache2

mv /etc/snmp/snmp.conf /etc/snmp/Old_snmp.conf
echo "
# As the snmp packages come without MIB files due to license reasons, loading
# of MIBs is disabled by default. If you added the MIBs you can reenable
# loading them by commenting out the following line.
mibs +ALL
mibAllowUnderline 1
" > /etc/snmp/snmp.conf

cp mibs_conectcor/* /usr/share/snmp/mibs/

echo "Creating database zabbix"
mysql -e "create database zabbix character set utf8 collate utf8_bin;"

echo "Creating user zabbix"
mysql -e "create user zabbix@localhost identified by '$SENHA';"

echo "Grant permissions on tables"
mysql -e "grant all privileges on zabbix.* to zabbix@localhost;"

echo "Importing zabbix schema to DB"
zcat /usr/share/doc/zabbix-sql-scripts/mysql/server.sql.gz | mysql -uzabbix -p$SENHA zabbix


sed -i "s@Server=127.0.0.1@Server=$SERVIDOR@g" /etc/zabbix/zabbix_server.conf
sed -i "s@Hostname=Zabbix server@Hostname=$HOSTNAME@g" /etc/zabbix/zabbix_server.conf
sed -i "s@DBUser=zabbix@DBUser="zabbix"@g" /etc/zabbix/zabbix_server.conf
sed -i "s@# DBPassword=@ DBPassword=$SENHA@g" /etc/zabbix/zabbix_server.conf


systemctl enable zabbix-server.service
systemctl restart zabbix-server.service
