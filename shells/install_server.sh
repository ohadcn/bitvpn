cd "$(dirname "$0")"

sudo apt update
sudo apt -y dist-upgrade
sudo apt -y install openvpn easy-rsa htop python3-flask python3-requests git curl

sudo cp server.conf /etc/openvpn/
sudo ./create_certs.sh
 
if [ -x /usr/sbin/ufw ] then
	sudo sed -i '/### RULES ###/a ### tuple ### allow tcp 8000 0.0.0.0/0 any 0.0.0.0/0 in\n-A ufw-user-input -p tcp --dport 8000 -j ACCEPT\n### tuple ### allow tcp 5000 0.0.0.0/0 any 0.0.0.0/0 in\n-A ufw-user-input -p tcp --dport 5000 -j ACCEPT' /etc/ufw/user.rules
	sudo ufw reload
fi

sudo service openvpn restart

#TODO: check in which directory we are installed
echo "@reboot cd $HOME/bitvpn/pythons && python3 ninja_server.py" > /tmp/cron
echo "@reboot cd $HOME/bitvpn/sheels && iptables.sh" >> /tmp/cron
sudo crontab -l -u root | cat - /tmp/cron | sudo crontab -u root -
#TODO check server at 5000 [no / request[]
CCIPADDRESS=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
echo $CCIPADDRESS > /tmp/current_ip
# todo sed to 636.
CCPORTADDRESS=636

sed -i s/__MYIP__/$CCIPADDRESS/g ~/bitvpn/pythons/server_config.ini
#sed -i s/107.172.2.189/$CCIPADDRESS/g /home/ubuntu/BitVpn/pythons/server_config.ini
#sed -i s/__MYIP__/$CCIPADDRESS/g server_config.ini


cd /home/ubuntu/bitvpn/pythons && python3 ninja_server.py &
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
