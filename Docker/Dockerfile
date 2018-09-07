FROM ubuntu:16.04

USER    root
ARG     PRIVKEY_ARG
RUN     test -n "$PRIVKEY_ARG"
ARG     PORT_ARG
RUN     test -n "$PORT_ARG"
ARG     RPCUSER
RUN     test -n "$RPCUSER"
ARG     RPCPASSWORD
RUN     test -n "$RPCPASSWORD"

        #Update and install some dependencies
RUN     apt-get update && apt-get install -y \
        zip unzip curl git wget cron python3-pip monit;

RUN     cd ~; \
        SYSTEM=$(uname -m); \
        if [ "$SYSTEM" = "x86_64" ]; then \
            wget https://github.com/allgamescoindev/allgamescoin/releases/download/v0.2.0/allgamescoin-v0.2.0-linux-64bits.zip; \
            unzip -o ~/allgamescoin-v0.2.0-linux-64bits.zip -d ~/wallet/; \
        else \
            wget https://github.com/allgamescoindev/allgamescoin/releases/download/v0.2.0/allgamescoin-v0.2.0-linux-32bits.zip; \
            unzip -o ~/allgamescoin-v0.2.0-linux-32bits.zip -d ~/wallet/; \
        fi; \
        install -m 0755 -o root -g root -t /usr/local/bin ~/wallet/*; \
        mkdir ~/.allgamescoincore; \
        #RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1); \
        #RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1); \
        NODEIP=$(curl -s4 api.ipify.org); \
        #Setting up config
        echo "rpcuser=$RPCUSER" >> ~/.allgamescoincore/allgamescoin.conf; \
        echo "rpcpassword=$RPCPASSWORD" >> ~/.allgamescoincore/allgamescoin.conf; \
        echo "rpcallowip=127.0.0.1" >> ~/.allgamescoincore/allgamescoin.conf; \
        echo "rpcport=7207" >> ~/.allgamescoincore/allgamescoin.conf; \
        echo "server=1" >> ~/.allgamescoincore/allgamescoin.conf; \
        echo "listen=1" >> ~/.allgamescoincore/allgamescoin.conf; \
        echo "daemon=1" >> ~/.allgamescoincore/allgamescoin.conf; \
        echo "logtimestamps=1" >> ~/.allgamescoincore/allgamescoin.conf; \
        echo "maxconnections=256" >> ~/.allgamescoincore/allgamescoin.conf; \
        echo "staking=0" >> ~/.allgamescoincore/allgamescoin.conf; \
        echo "externalip=$NODEIP:$PORT_ARG" >> ~/.allgamescoincore/allgamescoin.conf; \
        echo "masternode=1" >> ~/.allgamescoincore/allgamescoin.conf; \
        echo "masternodeprivkey=$PRIVKEY_ARG" >> ~/.allgamescoincore/allgamescoin.conf; \
        # Installing Sentinel and adding to crontab
        pip3 install virtualenv; \
        cd ~; \
        git clone https://github.com/allgamescoindev/sentinel.git && cd sentinel; \
        virtualenv ./venv; \
        ./venv/bin/pip install -r requirements.txt; \
        echo "* * * * *    root    cd /root/sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" >> /etc/crontab; \
        # Install monit to restart the daemon automatically
        echo "" > /etc/monit/conf-enabled/dummy; \
        echo "check process allgamescoind with pidfile /root/.allgamescoincore/allgamescoind.pid" > /etc/monit/conf.d/allgamescoin; \
        echo "      start program = \"/usr/local/bin/allgamescoind --daemon -datadir=/root/.allgamescoincore\" "  >> /etc/monit/conf.d/allgamescoin;

CMD     /usr/local/bin/allgamescoind --daemon -datadir=/root/.allgamescoincore && monit -I