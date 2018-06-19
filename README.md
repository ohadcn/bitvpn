to install the server (on a vanilla debian or ubuntu machine), just run:

    git clone https://github.com/ohadcn/bitvpn.git
    cd bitvpn/shells
    sudo ./install_server.sh
    
the default port for the managing service is 5000 TCP, and the default port for the vpn service is 1194 UDP, make sure both are open in your firewall.
    
to install the client:

a. install openvpn.

b. clone this repo. 

c. install python 3

d. open `client_config.ini` and make sure `ovpn_bin` is pointing to the right executable.

running the client (as root / admin):

    python3 ninja_client.py
    
    
currently only our servers are known to be online, and they will accept you even if your wallet is empty and you haven't opened a payment channel.
