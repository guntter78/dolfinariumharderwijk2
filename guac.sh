#!/bin/bash

# Variables
TOMCAT_VERSION="9.0.97"
GUACAMOLE_VERSION="1.5.5"
MYSQL_PASSWORD="YourStrongPassword"

# Update system
sudo apt update
sudo apt upgrade -y

# Install required packages
sudo apt install -y openjdk-11-jdk wget curl gcc g++ libcairo2-dev libjpeg-turbo8-dev libpng-dev libtool-bin \
    libossp-uuid-dev libavcodec-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev \
    libssh2-1-dev libvncserver-dev libtelnet-dev libssl-dev libvorbis-dev libwebp-dev make \
    build-essential libpulse-dev libwebsockets-dev unzip mysql-server

# Java check
java -version || { echo "Java installation failed."; exit 1; }

# Create tomcat user
sudo useradd -m -U -d /opt/tomcat -s /bin/false tomcat

# Install Tomcat
wget https://downloads.apache.org/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz -P /tmp
sudo tar -xf /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /opt/tomcat/
sudo ln -s /opt/tomcat/apache-tomcat-${TOMCAT_VERSION} /opt/tomcat/latest
sudo chown -R tomcat: /opt/tomcat
sudo chmod +x /opt/tomcat/latest/bin/*.sh

# Tomcat service setup
cat << EOF | sudo tee /etc/systemd/system/tomcat.service
[Unit]
Description=Tomcat 9 servlet container
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom -Djava.awt.headless=true"

Environment="CATALINA_BASE=/opt/tomcat/latest"
Environment="CATALINA_HOME=/opt/tomcat/latest"
Environment="CATALINA_PID=/opt/tomcat/latest/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/latest/bin/startup.sh
ExecStop=/opt/tomcat/latest/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now tomcat

# Open firewall for Tomcat
sudo ufw allow 8080/tcp

# Install Guacamole Server
wget https://downloads.apache.org/guacamole/${GUACAMOLE_VERSION}/source/guacamole-server-${GUACAMOLE_VERSION}.tar.gz
tar -xzf guacamole-server-${GUACAMOLE_VERSION}.tar.gz
cd guacamole-server-${GUACAMOLE_VERSION}
./configure --with-init-dir=/etc/init.d
make
sudo make install
sudo ldconfig
cd ..

# Install Guacamole Client
sudo mkdir -p /etc/guacamole
sudo wget https://downloads.apache.org/guacamole/${GUACAMOLE_VERSION}/binary/guacamole-${GUACAMOLE_VERSION}.war -O /etc/guacamole/guacamole.war
sudo mkdir -p /opt/tomcat/latest/webapps/guacamole
sudo unzip /etc/guacamole/guacamole.war -d /opt/tomcat/latest/webapps/guacamole

# Install JDBC extension and MySQL connector
wget https://downloads.apache.org/guacamole/${GUACAMOLE_VERSION}/binary/guacamole-auth-jdbc-${GUACAMOLE_VERSION}.tar.gz
tar -xzf guacamole-auth-jdbc-${GUACAMOLE_VERSION}.tar.gz
sudo cp guacamole-auth-jdbc-${GUACAMOLE_VERSION}/mysql/guacamole-auth-jdbc-mysql-${GUACAMOLE_VERSION}.jar /etc/guacamole/extensions/

wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.33.tar.gz
tar -xvf mysql-connector-java-8.0.33.tar.gz
sudo cp mysql-connector-java-8.0.33/mysql-connector-java-8.0.33.jar /etc/guacamole/lib/

# Configure MySQL database
sudo mysql --execute="CREATE DATABASE guacamole_db;"
sudo mysql --execute="CREATE USER 'guacamole_user'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_PASSWORD}';"
sudo mysql --execute="GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'localhost';"
sudo mysql --execute="FLUSH PRIVILEGES;"

# Import Guacamole schema
cat guacamole-auth-jdbc-${GUACAMOLE_VERSION}/mysql/schema/*.sql | sudo mysql guacamole_db || {
    echo "Error importing schema. Check the MySQL logs.";
    exit 1;
}

# Configure Guacamole properties
echo "mysql-hostname: localhost
mysql-port: 3306
mysql-database: guacamole_db
mysql-username: guacamole_user
mysql-password: ${MYSQL_PASSWORD}
guacd-hostname: localhost
guacd-port: 4822" | sudo tee /etc/guacamole/guacamole.properties

# Adjust permissions
sudo chmod 644 /etc/guacamole/guacamole.properties
sudo chown tomcat: /etc/guacamole/guacamole.properties
sudo chown -R tomcat: /etc/guacamole
sudo chmod -R 755 /etc/guacamole

# Reset MySQL user and set up initial admin account
sudo mysql -u guacamole_user -p${MYSQL_PASSWORD} -D guacamole_db -e "
DELETE FROM guacamole_user WHERE entity_id IN (SELECT entity_id FROM guacamole_entity WHERE name='guacadmin');
DELETE FROM guacamole_entity WHERE name='guacadmin';
INSERT INTO guacamole_entity (name, type) VALUES ('guacadmin', 'USER');
SET @entity_id = LAST_INSERT_ID();
INSERT INTO guacamole_user (entity_id, password_hash, password_salt, password_date, disabled)
VALUES (@entity_id, UNHEX(SHA2(CONCAT('guacadmin', 'salt'), 256)), 'salt', NOW(), 0);" || {
    echo "Error configuring admin user. Check the MySQL logs.";
    exit 1;
}
# Restart services
sudo systemctl restart guacd
sudo systemctl restart tomcat

# Open firewall ports
sudo ufw allow 22/tcp
sudo ufw --force enable

echo "Guacamole installation complete."
echo "Visit: http://<SERVER_IP>:8080/guacamole/"
echo "Default Login: guacadmin / guacadmin"
echo "Please change the default credentials immediately."
