#install-zbx5
#!/bin/bash
read -p "Digite a senha do banco de dados: " SENHA
read -p "Digite o IP do Zabbix Server: " SERVIDOR
read -p "Digite o Hostname do Zabbix : " HOSTNAME



apt update && apt upgrade -y

locale-gen pt_BR.UTF-8
dpkg-reconfigure locales
update-locale LANG=pt_BR.UTF-8


echo " 

Instalando Banco 

"
apt install postgresql postgresql-contrib  -y

service postgresql start
systemctl enable postgresql

echo "Creating database zabbix"
#mysql -e "create database zabbix character set utf8 collate utf8_bin;"
sudo -u postgres createuser --pwprompt zabbix;
echo $SENHA
echo $SENHA

echo "Creating user zabbix"
#mysql -e "create user zabbix@localhost identified by '$SENHA';"
sudo -u postgres createdb -O zabbix -E Unicode -T template0 zabbix;
echo $SENHA

#echo "Grant permissions on tables"
#mysql -e "grant all privileges on zabbix.* to zabbix@localhost;"

sed -i "s@local   all             postgres                                peer@local   all             postgres                                trust@g" /etc/postgresql/12/main/pg_hba.conf

#pg_ctlcluster 12 main start


echo "Importing zabbix schema to DB"
zcat /usr/share/doc/zabbix-sql-scripts/postgresql/create.sql.gz | psql -U zabbix -d zabbix 
#&>/dev/null
#zcat /usr/share/doc/zabbix-sql-scripts/mysql/server.sql.gz | mysql -uzabbix -p$SENHA zabbix





echo "Cancelar caso não queira seguir com a instalação do server zabbix"

echo "

Instalando aplicações

"
cd /tmp
wget https://repo.zabbix.com/zabbix/5.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.0-1%2Bfocal_all.deb
dpkg -i zabbix-release_5.0-1+focal_all.deb


apt install zabbix-server-pgsql zabbix-frontend-php php-pgsql zabbix-apache-conf zabbix-agent snmp snmp-mibs-downloader apache2 libapache2-mod-php php php-mysql php-cli php-pear php-gmp php-gd php-bcmath php-mbstring php-curl php-xml php-zip -y

a2enmod rewrite

sed -i 's/ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-available/security.conf
sed -i 's/ServerSignature On/ServerSignature Off/' /etc/apache2/conf-available/security.conf
sed -i "s@;date.timezone =@date.timezone = America/Sao_Paulo@g" /etc/php/7.4/apache2/php.ini



systemctl reload apache2
systemctl enable apache2

#psql -U postgres

mv /etc/snmp/snmp.conf /etc/snmp/Old_snmp.conf
echo "
# As the snmp packages come without MIB files due to license reasons, loading
# of MIBs is disabled by default. If you added the MIBs you can reenable
# loading them by commenting out the following line.
mibs +ALL
mibAllowUnderline 1
" > /etc/snmp/snmp.conf

cp mibs_ccor/* /usr/share/snmp/mibs/


cd /tmp





sed -i "s@Server=127.0.0.1@Server=$SERVIDOR@g" /etc/zabbix/zabbix_server.conf
sed -i "s@Hostname=Zabbix server@Hostname=$HOSTNAME@g" /etc/zabbix/zabbix_server.conf
sed -i "s@DBUser=zabbix@DBUser="zabbix"@g" /etc/zabbix/zabbix_server.conf
sed -i "s@# DBPassword=@ DBPassword=$SENHA@g" /etc/zabbix/zabbix_server.conf


systemctl enable zabbix-server.service
systemctl restart zabbix-server.service
