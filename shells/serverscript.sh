# Script to be run under netninja user
echo "Please note, Amazon user must have the following permitions: AmazonEC2FullAccess, CloudWatchFullAccess, AmazonEC2ContainerServiceFullAccess"
cd ~
mkdir -p ~/.ssh
chmod 0700 ~/.ssh
cd ~/.ssh
SSHKEYPASSWORD=$(openssl rand -hex 12)
echo "Password for SSH Key AT ~/.ssh/id_rsa: $SSHKEYPASSWORD"
ssh-keygen -t rsa -f ~/.ssh/id_rsa -P $SSHKEYPASSWORD

cat << EOF > ~/.ssh/config
Host *
    HashKnownHosts no
    AddKeysToAgent yes
EOF

echo " ~/.ssh/config Created"

# ./streisand < $CONFIGFILE > $LOGFILE

# TODO: remove not needed ssh-add commands

# HOW TO ADD IT!!
# exec ssh-agent bash
#eval `ssh-agent -c`
#ssh-agent /bin/sh
# NEED -s or bash , but clean enviroment!!!ssh

eval `ssh-agent -s`

# exec ssh-agent bash -c "echo changeme | ssh-add -K ~/.ssh/id_rsa"
# eval ssh-agent bash -c "echo changeme | ssh-add -K ~/.ssh/id_rsa"
#echo -e '#!/bin/bash\necho changeme'>/tmp/test.sh
#chmod +X /tmp/test.sh
#eval `ssh-agent bash -c "echo changeme | SSH_ASKPASS==/tmp/test.sh ssh-add ~/.ssh/id_rsa"`

echo "SSH TO ADDED"

echo $SSHKEYPASSWORD | ssh-add ~/.ssh/id_rsa
TEMPFILEWHY=$(mktemp)
echo -e '#!/bin/bash\necho '$SSHKEYPASSWORD > $TEMPFILEWHY.sh
chmod +x $TEMPFILEWHY.sh
echo "Created $TEMPFILEWHY.sh , SSHKEYPASSWORD = $SSHKEYPASSWORD"
echo $SSHKEYPASSWORD | SSH_ASKPASS="$TEMPFILEWHY.sh" ssh-add
echo "SSH KEY ADD TEST"
# ssh-keygen -y -f ~/.ssh/id_rsa

echo "Start INSTALL"

sudo apt-get install -y git python-paramiko python-pip python-pycurl python-dev build-essential
sudo pip install ansible markupsafe
sudo pip install boto boto3
cd ~
git clone https://github.com/StreisandEffect/streisand.git && cd streisand

# cp -r /tmp/streisand ./streisand && cd streisand # instead of git clone ...

#add 5000 + 8000 to amazon inbound rules firewall

sed -i '/s Encrypt/s/^/      # 8000\n      # ---\n      - proto: tcp\n        from_port: 8000\n        to_port: 8000\n        cidr_ip: 0.0.0.0\/0\n      # 5000\n      # ---\n      - proto: tcp\n        from_port: 5000\n        to_port: 5000\n        cidr_ip: 0.0.0.0\/0\n/' ./playbooks/roles/ec2-security-group/tasks/main.yml 

echo "What is your AWS Access Key ID?"
read AWS_SECRET_KEY_ID
echo "What is your AWS Secret Access Key?"
read AWS_SECRET_ACCESS_KEY

echo "AWS_SECRET_KEY_ID = $AWS_SECRET_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY = $AWS_SECRET_ACCESS_KEY"


# maybe run for init
# ./streisand

echo "streisand INIT"

# Create amazon config file
AMAZONCONFIGFILEDEF='./global_vars/noninteractive/amazon-site.yml'
AMAZONCONFIGFILENEW='./global_vars/noninteractive/amazon-site-new.yml'
cp $AMAZONCONFIGFILEDEF $AMAZONCONFIGFILENEW

AWS_SECRET_KEY_ID_ESCAPED=${AWS_SECRET_KEY_ID//[\/]/\\/}
AWS_SECRET_ACCESS_KEY_ESCAPED=${AWS_SECRET_ACCESS_KEY//[\/]/\\/}
sed -i "/^aws_access_key:/s/\".*\"/\"$AWS_SECRET_KEY_ID_ESCAPED\"/" $AMAZONCONFIGFILENEW
sed -i "/^aws_secret_key:/s/\".*\"/\"$AWS_SECRET_ACCESS_KEY_ESCAPED\"/" $AMAZONCONFIGFILENEW

# AMAZONCONFIGFILENEW='amazon-site-new.yml'
sed -i "/^streisand_openconnect_enabled:/s/ yes/ no/" $AMAZONCONFIGFILENEW
sed -i "/^streisand_shadowsocks_enabled:/s/ yes/ no/" $AMAZONCONFIGFILENEW
sed -i "/^streisand_ssh_forward_enabled:/s/ yes/ no/" $AMAZONCONFIGFILENEW
sed -i "/^streisand_stunnel_enabled:/s/ yes/ no/" $AMAZONCONFIGFILENEW
sed -i "/^streisand_tinyproxy_enabled:/s/ yes/ no/" $AMAZONCONFIGFILENEW
sed -i "/^streisand_tor_enabled:/s/ yes/ no/" $AMAZONCONFIGFILENEW
sed -i "/^streisand_wireguard_enabled:/s/ yes/ no/" $AMAZONCONFIGFILENEW

./deploy/streisand-new-cloud-server.sh --provider amazon --site-config $AMAZONCONFIGFILENEW

AMAZON_SERVER_IP=$(cat ~/.ssh/known_hosts | tr ' ' '\n' | head -n 1)

echo "Connecting to IP: $AMAZON_SERVER_IP"

ssh $AMAZON_SERVER_IP -lubuntu <<-'ENDSSH'

# REMOTE SCRIPT #

cd ~
git clone https://github.com/ohadcn/BitVpn 

sudo sed -i '/### RULES ###/a ### tuple ### allow tcp 8000 0.0.0.0/0 any 0.0.0.0/0 in\n-A ufw-user-input -p tcp --dport 8000 -j ACCEPT\n### tuple ### allow tcp 5000 0.0.0.0/0 any 0.0.0.0/0 in\n-A ufw-user-input -p tcp --dport 5000 -j ACCEPT' /etc/ufw/user.rules

sudo ufw reload

echo "status openvpn-status.log" | sudo tee -a /etc/openvpn/server.conf
sudo systemctl restart openvpn@server.service

sudo apt-get install -y  easy-rsa python3-flask python3-requests # flask requests tshark

# add to crontab
echo '@reboot cd /home/ubuntu/BitVpn/pythons && python3 ninja_server.py' > /tmp/cron
sudo crontab -l -u root | cat - /tmp/cron | sudo crontab -u root -


#TODO check server at 5000 [no / request[]

CCIPADDRESS=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
echo $CCIPADDRESS > /tmp/current_ip
# todo sed to 636.
CCPORTADDRESS=636
# TODO: change to: find 'port 636' in 'sudo cat /etc/openvpn/server.conf'
#A=$(grep "^port " /etc/openvpn/server.conf) #add substring of 5

sudo bash -c 'cat << EOF > /etc/openvpn/client-common.txt
client
dev tun
proto udp
sndbuf 0
rcvbuf 0
remote $CCIPADDRESS $CCPORTADDRESS
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth SHA512
cipher AES-256-CBC
comp-lzo
setenv opt block-outside-dns
key-direction 1
verb 3
EOF'

sed -i s/__MYIP__/$CCIPADDRESS/g /home/ubuntu/BitVpn/pythons/server_config.ini
#sed -i s/107.172.2.189/$CCIPADDRESS/g /home/ubuntu/BitVpn/pythons/server_config.ini
#sed -i s/__MYIP__/$CCIPADDRESS/g server_config.ini

EASYRSAURL='https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.4/EasyRSA-3.0.4.tgz'
wget -O ~/easyrsa.tgz "$EASYRSAURL" 2>/dev/null || curl -Lo ~/easyrsa.tgz "$EASYRSAURL"
tar xzf ~/easyrsa.tgz -C ~/
rm -rf ~/easyrsa.tgz
sudo mv ~/EasyRSA-3.0.4/ /etc/openvpn/
sudo mkdir -p /etc/openvpn/easy-rsa/pki
sudo mv /etc/openvpn/EasyRSA-3.0.4/ /etc/openvpn/easy-rsa/ #TODO why 2 mv?
sudo chown -R root:root /etc/openvpn/easy-rsa/

# TODO: generate per client script

sudo -i
cd /etc/openvpn/easy-rsa/EasyRSA-3.0.4
# Create the PKI, set up the CA, the DH params and the server + client certificates
./easyrsa init-pki
./easyrsa --batch build-ca nopass
./easyrsa gen-dh
./easyrsa build-server-full server nopass
clientname=client
./easyrsa build-client-full $clientname nopass #parameter client name
EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl
# Move the stuff we need
cp pki/ca.crt pki/private/ca.key pki/dh.pem pki/issued/server.crt pki/private/server.key pki/crl.pem /etc/openvpn
# CRL is read with each client connection, when OpenVPN is dropped to nobody

#TODO what group name is? GROUPNAME nobody/vpn?
GROUPNAME=root

chown nobody:$GROUPNAME /etc/openvpn/crl.pem
# Generate key for tls-auth
openvpn --genkey --secret /etc/openvpn/ta.key

# TODO: run ninja_server.py on reboot
cd /home/ubuntu/BitVpn/pythons && python3 ninja_server.py &

sleep 15

VPNSERVERS=$(curl https://btc.oodi.co.il/netninja/get_servers/100)
IPTOCHECK=$(cat /tmp/current_ip)
echo "VPNSERVERS = $VPNSERVERS"
echo "IPTOCHECK = $IPTOCHECK"
if [[ $VPNSERVERS = *"$IPTOCHECK"* ]]; then
  echo "GOOD!! IP of New VPN Added to VPN lists!"
else
  echo "BAD!! IP not added to VPN lists"
fi

ENDSSH
