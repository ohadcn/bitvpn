CURRENTIP=$(curl http://ipinfo.io/ip)
echo "CURRENTIP = $CURRENTIP"
cd ~
git clone https://github.com/ohadcn/BitVpn 
cd ~/BitVpn/pythons
sed -i 's/ovpn_bin=.*/ovpn_bin=\/usr\/sbin\/openvpn/g' client_config.ini
echo "Installing openvpn client"
sudo apt-get install -y openvpn
sudo python3 ninja_client.py &
sleep 15
NEWIP=$(curl http://ipinfo.io/ip)
echo "NEWIP = $NEWIP"
[ "$NEWIP" == "$CURRENTIP" ] && echo "ERROR: IP NOT CHANGED"
