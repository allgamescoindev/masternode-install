#!/bin/bash
output() {
    printf "\E[0;33;40m"
    echo $1
    printf "\E[0m"
}

#Input
output "Make sure you have mortgaged 1000XAGC in your local wallet."
output ""
read -e -p "Please enter your masternode key and press ENTER: " masternodekey
read -e -p "Install UFW and configure ports? [Y/n] : " UFW
output ""

output "Update and install some dependencies"
sudo apt-get update;
sudo apt-get upgrade -y;
sudo apt-get install -y zip unzip curl git wget;

if [[ ("$UFW" == "y" || "$UFW" == "Y" || "$UFW" == "") ]]; then
output "Install UFW and configure ports"
sudo apt-get install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 22;
sudo ufw allow 7207;
sudo ufw allow 7208;
sudo ufw --force enable    
fi

output "Checking if total system memory is less than 2 GB, if so create swap space"
#Check if swap need to be enabled.
totalk=$(awk '/^MemTotal:/{print $2}' /proc/meminfo) ;
if [ $totalk -lt 2097152 ] ; then
    output "Total system memory is less than 2 GB, attempting to create swap space";
    cd;
    sudo dd if=/dev/zero of=swapfile bs=1M count=3000;
    sudo mkswap swapfile;
    #sudo chmod 600 swapfile;
    sudo swapon swapfile;
    echo "/swapfile none swap sw 0 0" >> /etc/fstab;
fi

output "Downloading AllGamesCoin wallet/daemon";
cd ~;
SYSTEM=$(uname -m);
if [ "$SYSTEM" = "x86_64" ]; then
    wget https://github.com/allgamescoindev/allgamescoin/releases/download/v0.2.0/allgamescoin-v0.2.0-linux-64bits.zip;
    unzip -o ~/allgamescoin-v0.2.0-linux-64bits.zip -d ~/wallet/;
else
    wget https://github.com/allgamescoindev/allgamescoin/releases/download/v0.2.0/allgamescoin-v0.2.0-linux-32bits.zip;
    unzip -o ~/allgamescoin-v0.2.0-linux-32bits.zip -d ~/wallet/;
fi

output "Installing AllGamesCoin wallet/daemon";
install -m 0755 -o root -g root -t /usr/local/bin ~/wallet/*;
mkdir ~/.allgamescoincore;
RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1);
RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1);
NODEIP=$(curl -s4 api.ipify.org);

output "Setting up config";
echo "rpcuser=$RPCUSER" >> ~/.allgamescoincore/allgamescoin.conf;
echo "rpcpassword=$RPCPASSWORD" >> ~/.allgamescoincore/allgamescoin.conf;
echo "rpcallowip=127.0.0.1" >> ~/.allgamescoincore/allgamescoin.conf;
echo "rpcport=7207" >> ~/.allgamescoincore/allgamescoin.conf;
echo "bind=$NODEIP" >> ~/.allgamescoincore/allgamescoin.conf;
echo "server=1" >> ~/.allgamescoincore/allgamescoin.conf;
echo "listen=1" >> ~/.allgamescoincore/allgamescoin.conf;
echo "daemon=1" >> ~/.allgamescoincore/allgamescoin.conf;
echo "logtimestamps=1" >> ~/.allgamescoincore/allgamescoin.conf;
echo "maxconnections=256" >> ~/.allgamescoincore/allgamescoin.conf;
echo "staking=0" >> ~/.allgamescoincore/allgamescoin.conf;
echo "externalip=$NODEIP:7208" >> ~/.allgamescoincore/allgamescoin.conf;
echo "masternode=1" >> ~/.allgamescoincore/allgamescoin.conf;
echo "masternodeprivkey=$masternodekey" >> ~/.allgamescoincore/allgamescoin.conf;

sudo sed -i '13i\allgamescoind --daemon -datadir=/root/.allgamescoincore'  /etc/rc.local;

output "Run allgamescoind";
allgamescoind --daemon -datadir=$HOME/.allgamescoincore

output "Installing Sentinel";
apt-get install python3-pip -y;
pip3 install virtualenv;
cd ~;
git clone https://github.com/allgamescoindev/sentinel.git && cd sentinel;
virtualenv ./venv;
./venv/bin/pip install -r requirements.txt;
echo "* * * * *    root    cd /root/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" >> /etc/crontab

output "=== Install script finished! ";
output "=== Your Node ip: $NODEIP:7208 | rpcuser=$RPCUSER | rpcpassword=$RPCPASSWORD";
output "=== Start your node by running command: allgamescoind --daemon -datadir=$HOME/.allgamescoincore ";
output "=== Check blockchain sync with command: allgamescoin-cli getblockcount ";
output "=== Check node status with command: allgamescoin-cli masternode status ";
output "=== Local wallet masternode.conf : mn1 $NODEIP:7208 $masternodekey tx_id(look for it in history) digit(0 or 1) ";
