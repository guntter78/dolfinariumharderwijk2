#!/bin/bash

# Systeem updaten
sudo apt update
sudo apt upgrade -y

# Benodigde pakketten installeren
sudo apt install -y wget curl gcc g++ libcairo2-dev libjpeg-turbo8-dev libpng-dev libtool-bin libossp-uuid-dev libavcodec-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libvncserver-dev libtelnet-dev libssl-dev libvorbis-dev libwebp-dev tomcat9 tomcat9-admin tomcat9-common tomcat9-user

# Guacamole server installeren
VERSION="1.5.5"
wget "https://downloads.apache.org/guacamole/${VERSION}/source/guacamole-server-${VERSION}.tar.gz"
tar -xzf "guacamole-server-${VERSION}.tar.gz"
cd "guacamole-server-${VERSION}"
./configure --with-init-dir=/etc/init.d
make
sudo make install
sudo ldconfig
cd ..

# Guacamole client installeren
sudo mkdir /etc/guacamole
sudo wget "https://downloads.apache.org/guacamole/${VERSION}/binary/guacamole-${VERSION}.war" -O /etc/guacamole/guacamole.war
sudo ln -s /etc/guacamole/guacamole.war /var/lib/tomcat9/webapps/

# Guacamole configureren
echo "guacd-hostname: localhost
guacd-port: 4822
user-mapping: /etc/guacamole/user-mapping.xml
auth-provider: net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider" | sudo tee /etc/guacamole/guacamole.properties

# Basis user-mapping.xml aanmaken
echo "<user-mapping>
    <authorize username=\"guacadmin\" password=\"guacadmin\">
        <connection name=\"SSH\">
            <protocol>ssh</protocol>
            <param name=\"hostname\">localhost</param>
            <param name=\"port\">22</param>
        </connection>
    </authorize>
</user-mapping>" | sudo tee /etc/guacamole/user-mapping.xml

# Guacamole services starten
sudo systemctl start guacd
sudo systemctl restart tomcat9

# Firewall configureren
sudo ufw allow 8080/tcp
sudo ufw allow 22/tcp
sudo ufw --force enable

echo "Guacamole installatie voltooid. Je kunt nu inloggen op http://SERVER_IP:8080/guacamole/"
echo "Standaard inloggegevens: guacadmin / guacadmin"
echo "Verander dit wachtwoord zo snel mogelijk ofzo!"
