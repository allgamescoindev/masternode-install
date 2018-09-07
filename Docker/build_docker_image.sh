#!/bin/bash

output() {
    printf "\E[0;33;40m"
    echo $1
    printf "\E[0m"
}

#Input
output "Make sure you have mortgaged 1000XAGC in your local wallet."
output ""
read -e -p "Please enter name for this Docker image and press ENTER: " imagename
read -e -p "Please enter name for the Docker Container that will be running and press ENTER: " containername
read -e -p "Please enter your masternode key and press ENTER: " masternodekey
read -e -p "Install UFW and configure ports? [Y/n] : " UFW
output ""

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

RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1);
RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1);
NODEIP=$(curl -s4 api.ipify.org);

output "Building Docker image";

sudo docker build -t $imagename --build-arg PRIVKEY_ARG=$masternodekey --build-arg PORT_ARG=7207 --build-arg RPCUSER=$RPCUSER --build-arg RPCPASSWORD=$RPCPASSWORD .;

if [ $? -eq 0 ] ; then
    output "=== Succesfull built Docker image ===";
    output "=== Run your container by running \"docker run -d -p 7207:7207 -p 7208:7208 --name $containername $imagename\" ===";
    output "=== Your Node ip: $NODEIP:7207 | rpcuser=$RPCUSER | rpcpassword=$RPCPASSWORD ===";
    output "=== Check blockchain sync with command: docker exec -it $containername bash allgamescoin-cli getblockcount ";
    output "=== Check node status with command: docker exec -it $containername bash allgamescoin-cli masternode status";
    output "=== Local wallet masternode.conf : mn1 $NODEIP:7207 $masternodekey tx_id(look for it in history) digit(0 or 1) ";
fi