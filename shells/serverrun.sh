#!/bin/bash

# sudo deluser netninja #

# TODO: Test on New Ubuntu 18 minimal installation, currently tested on ubuntu 17.10 #

NETNINJAUSER=netninja
sudo adduser $NETNINJAUSER --disabled-password --gecos "First Last, Room Number,WorkPhone,HomePone"
NETNINJAPASSWORD=$(openssl rand -hex 12)
echo "Password $NETNINJAPASSWORD for user $NETNINJAUSER"
echo "netninja:$NETNINJAPASSWORD" | sudo chpasswd
sudo adduser $NETNINJAUSER sudo
echo "$NETNINJAUSER ALL = NOPASSWD : ALL" | sudo EDITOR='tee -a' visudo
SERVERSCRIPT='serverscript.sh'
cp ./$SERVERSCRIPT /tmp/$SERVERSCRIPT
sudo su - $NETNINJAUSER -c "bash /tmp/$SERVERSCRIPT"

#sudo su - $NETNINJAUSER
