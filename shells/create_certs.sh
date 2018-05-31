EASYRSAURL='https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.4/EasyRSA-3.0.4.tgz'
wget -O ~/easyrsa.tgz "$EASYRSAURL" 2>/dev/null || curl -Lo ~/easyrsa.tgz "$EASYRSAURL"
tar xzf ~/easyrsa.tgz -C ~/
rm -rf ~/easyrsa.tgz
mv -r ~/EasyRSA-3.0.4/ /etc/openvpn/
mkdir -p /etc/openvpn/easy-rsa/pki
mv /etc/openvpn/EasyRSA-3.0.4/ /etc/openvpn/easy-rsa/ #TODO why 2 mv?
chown -R root:root /etc/openvpn/easy-rsa/

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

GROUPNAME=root
chown nobody:$GROUPNAME /etc/openvpn/crl.pem
openvpn --genkey --secret /etc/openvpn/ta.key

