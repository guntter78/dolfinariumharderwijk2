#!/bin/bash

# Variabelen
TOMCAT_VERSION="9.0.97"
GUACAMOLE_VERSION="1.5.5"

# Systeem updaten
sudo apt update
sudo apt upgrade -y

# Nodige pakketten installeren
sudo apt install -y openjdk-11-jdk wget curl gcc g++ libcairo2-dev libjpeg-turbo8-dev libpng-dev libtool-bin \
    libossp-uuid-dev libavcodec-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev \
    libssh2-1-dev libvncserver-dev libtelnet-dev libssl-dev libvorbis-dev libwebp-dev make \
    build-essential libpulse-dev libwebsockets-dev unzip

# Java checken
java -version || { echo "Java installatie mislukt."; exit 1; }

# Tomcat gebruiker aanmaken
sudo useradd -m -U -d /opt/tomcat -s /bin/false tomcat

# Tomcat downloaden en installeren
wget https://downloads.apache.org/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz -P /tmp
sudo tar -xf /tmp/apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /opt/tomcat/
sudo ln -s /opt/tomcat/apache-tomcat-${TOMCAT_VERSION} /opt/tomcat/latest
sudo chown -R tomcat: /opt/tomcat
sudo chmod +x /opt/tomcat/latest/bin/*.sh

# Tomcat service instellen
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

# Firewall openen voor Tomcat
sudo ufw allow 8080/tcp

# Guacamole Server installeren
wget https://downloads.apache.org/guacamole/${GUACAMOLE_VERSION}/source/guacamole-server-${GUACAMOLE_VERSION}.tar.gz
tar -xzf guacamole-server-${GUACAMOLE_VERSION}.tar.gz
cd guacamole-server-${GUACAMOLE_VERSION}
./configure --with-init-dir=/etc/init.d
make
sudo make install
sudo ldconfig
cd ..

# Guacamole Client installeren
sudo mkdir -p /etc/guacamole
sudo wget https://downloads.apache.org/guacamole/${GUACAMOLE_VERSION}/binary/guacamole-${GUACAMOLE_VERSION}.war -O /etc/guacamole/guacamole.war
sudo mkdir -p /opt/tomcat/latest/webapps/guacamole
sudo unzip /etc/guacamole/guacamole.war -d /opt/tomcat/latest/webapps/guacamole

# Guacamole configureren
echo "guacd-hostname: localhost
guacd-port: 4822
user-mapping: /etc/guacamole/user-mapping.xml
auth-provider: net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider" | sudo tee /etc/guacamole/guacamole.properties

# Standaard gebruiker instellen
echo "<user-mapping>
    <authorize username=\"guacadmin\" password=\"guacadmin\">
        <connection name=\"SSH\">
            <protocol>ssh</protocol>
            <param name=\"hostname\">localhost</param>
            <param name=\"port\">22</param>
        </connection>
    </authorize>
</user-mapping>" | sudo tee /etc/guacamole/user-mapping.xml

# guacd configureren
cat << EOF | sudo tee /etc/guacamole/guacd.conf
[daemon]
pid_file = /var/run/guacd.pid

[server]
bind_host = 127.0.0.1
bind_port = 4822
EOF

# Rechten instellen
sudo chmod -R 644 /etc/guacamole
sudo chown -R tomcat: /etc/guacamole

# Guacamole starten
sudo systemctl restart guacd
sudo systemctl restart tomcat

# Firewall instellen
sudo ufw allow 22/tcp
sudo ufw --force enable

echo "Guacamole installatie klaar."
echo "Ga naar: http://<SERVER_IP>:8080/guacamole/"
echo "Login: guacadmin / guacadmin"
echo "Verander het wachtwoord meteen ofzo!"
