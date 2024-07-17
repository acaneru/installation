#!/bin/bash

#Harbor on Ubuntu 20.04

# Unless ENV VAR 'IPorFQDN' is already set in CLI,
# prompt for the user to ask if the install should use the IP Address or Fully Qualified Domain Name of the Harbor Server
if [ -z "$IPorFQDN" ];then
	PS3='Would you like to install Harbor based on IP or FQDN? '
	select option in IP FQDN
	do
		case $option in
			IP)
				IPorFQDN=$(hostname -I|cut -d" " -f 1)
				break;;
			FQDN)
				IPorFQDN=$(hostname -f)
				break;;
		esac
	done
fi

# Housekeeping
apt update -yq
swapoff --all
sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab
echo "Housekeeping done"

# Install Latest Stable Docker Release
apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -yq
apt-get install -y containerd.io=1.6.4-1 docker-ce=5:20.10.20~3-0~ubuntu-focal docker-ce-cli=5:20.10.20~3-0~ubuntu-focal
tee /etc/docker/daemon.json >/dev/null <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "insecure-registries" : ["$IPorFQDN:443","$IPorFQDN:80","0.0.0.0/0"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
mkdir -p /etc/systemd/system/docker.service.d
groupadd -f docker
MAINUSER=$(logname)
usermod -aG docker $MAINUSER
systemctl daemon-reload
systemctl restart docker
echo "Docker Installation done"

# Install Docker Compose
COMPOSEVERSION="v2.23.0"
curl -kL $(curl -s https://api.github.com/repos/docker/compose/releases/tags/$COMPOSEVERSION|grep browser_download_url|grep -i "$(uname -s)-$(uname -m)"|grep -v sha25|head -1|cut -d'"' -f4) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose || true
echo "Docker Compose Installation done"

# Install Harbor
HARBORVERSION="v2.7.3"
wget -q $(curl -s https://api.github.com/repos/goharbor/harbor/releases/tags/$HARBORVERSION|grep browser_download_url|grep online|cut -d'"' -f4|grep '.tgz$'|head -1) -O harbor-online-installer.tgz
tar xvf harbor-online-installer.tgz

cd harbor
cp harbor.yml.tmpl harbor.yml
sed -i "s/reg.mydomain.com/$IPorFQDN/g" harbor.yml
sed -e '/port: 443$/ s/^#*/#/' -i harbor.yml
sed -e '/https:$/ s/^#*/#/' -i harbor.yml
sed -e '/\/your\/certificate\/path$/ s/^#*/#/' -i harbor.yml
sed -e '/\/your\/private\/key\/path$/ s/^#*/#/' -i harbor.yml

mkdir -p /var/log/harbor
./install.sh --with-chartmuseum
echo -e "Harbor Installation Complete \n\nPlease log out and log in or run the command 'newgrp docker' to use Docker without sudo\n\nLogin to your harbor instance:\n docker login -u admin -p Harbor12345 $IPorFQDN"
