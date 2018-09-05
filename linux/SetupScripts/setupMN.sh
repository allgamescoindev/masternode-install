#!/bin/bash

#Update and install some dependencies

apt-get update;
apt-get upgrade -y;
apt-get install -y zip unzip curl git wget;
RED='\033[0;31m';
GREEN='\033[0;32m';
NC='\033[0m'; \


# Check if firewall installed, if so open required ports.
echo -e "$RED=== Checking if firewall is installed/active ===$NC";
ufw status | grep -qw active;
if (( $? == 0 ));then
    echo "$RED=== Firewall found, opening required ports ===$NC";
    ufw allow 22;
    ufw allow 7207;
    ufw allow 7208;
    ufw enable;
fi

echo -e "$RED=== Checking if total system memory is below 2 GB, if so create swap space ===$NC";
#Check if swap need to be enabled.
totalk=$(awk '/^MemTotal:/{print $2}' /proc/meminfo) ;
if (( $totalk <  1999999 )) ; then
    echo -e "$RED=== Total system memory is below 2 GB, attempting to create swap space ===$NC";
    cd;
    dd if=/dev/zero of=swapfile bs=1M count=3000;
    mkswap swapfile;
    chmod 600 swapfile;
    swapon swapfile;
    echo "/swapfile none swap sw 0 0" >> /etc/fstab;
fi

echo -e "$RED=== Downloading AllGamesCoin wallet/daemon ===$NC";
cd ~;
SYSTEM=$(uname -m);
if [ "$SYSTEM" = "x86_64" ]; then
    wget https://github.com/allgamescoindev/allgamescoin/releases/download/v0.2.0/allgamescoin-v0.2.0-linux-64bits.zip;
    unzip -o ~/allgamescoin-v0.2.0-linux-64bits.zip -d ~/wallet/;
else
    wget https://github.com/allgamescoindev/allgamescoin/releases/download/v0.2.0/allgamescoin-v0.2.0-linux-32bits.zip;
    unzip -o ~/allgamescoin-v0.2.0-linux-32bits.zip -d ~/wallet/;
fi

echo -e "$RED=== Installing AllGamesCoin wallet/daemon ===$NC";
install -m 0755 -o root -g root -t /usr/local/bin ~/wallet/*;
mkdir ~/.allgamescoincore;
RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1);
RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1);
NODEIP=$(curl -s4 api.ipify.org);


echo -e "$RED=== Setting up config ===$NC";
read -p "Please enter your masternode key and press ENTER: " masternodekey

echo "rpcuser=$RPCUSER" >> ~/.allgamescoincore/allgamescoin.conf;
echo "rpcpassword=$RPCPASSWORD" >> ~/.allgamescoincore/allgamescoin.conf;
echo "rpcallowip=127.0.0.1" >> ~/.allgamescoincore/allgamescoin.conf;
echo "rpcport=7207" >> ~/.allgamescoincore/allgamescoin.conf;
#echo "bind=$NODEIP" >> ~/.allgamescoincore/allgamescoin.conf;
echo "server=1" >> ~/.allgamescoincore/allgamescoin.conf;
echo "listen=1" >> ~/.allgamescoincore/allgamescoin.conf;
echo "daemon=1" >> ~/.allgamescoincore/allgamescoin.conf;
echo "logtimestamps=1" >> ~/.allgamescoincore/allgamescoin.conf;
echo "maxconnections=256" >> ~/.allgamescoincore/allgamescoin.conf;
echo "staking=0" >> ~/.allgamescoincore/allgamescoin.conf;
echo "externalip=$NODEIP:7208" >> ~/.allgamescoincore/allgamescoin.conf;
echo "masternode=1" >> ~/.allgamescoincore/allgamescoin.conf;
echo "masternodeprivkey=$masternodekey" >> ~/.allgamescoincore/allgamescoin.conf;

echo "allgamescoind --daemon -datadir=/root/.allgamescoincore" >> /etc/rc.local;

echo -e "$RED=== Installing Sentinel ===$NC";
apt-get install python3-pip -y;
pip3 install virtualenv;
cd ~;
git clone https://github.com/allgamescoindev/sentinel.git && cd sentinel;
virtualenv ./venv;
./venv/bin/pip install -r requirements.txt;


read -p "Attempt to add job for sentinel to crontab? (if this fails, add it manually please)  [Yy] " -n 1 -r;
if [[ $REPLY =~ ^[Yy]$ ]]
then
    crontab -l > mycron;
    echo "* * * * * cd /root/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" >> mycron;
    crontab mycron;
    rm mycron;
fi

echo -e "$GREEN=== Install script finished! ===$NC";
echo -e "$GREEN=== Your Node ip: $NODEIP:7208 ===$NC";
echo -e "$GREEN=== Start your node by running command: 'allgamescoind --daemon -datadir=/root/.allgamescoincore' ===$NC";
echo -e "$GREEN=== Check node status with command: 'allgamescoin-cli masternode status' ===$NC";
echo -e "$GREEN=== Check blockchain sync with command: 'allgamescoin-cli getblockcount' ===$NC";