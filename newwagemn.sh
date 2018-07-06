#!/bin/bash
clear
sleep 1
if [ -e getwageinfo.json ]
then
	echo " "
	echo "Script running already?"
	echo " "

else
echo "blah" > getwageinfo.json

THISHOST=$(hostname -s)

sudo apt-get install jq pwgen bc -y

#killall digiwaged
#rm -rf digiwage*
#rm -rf .digiwage*

cd ~
wget https://github.com/digiwage/digiwage/releases/download/v1.1.0/digiwage-1.1.0-x86_64-linux-gnu.tar.gz
tar -zxvf digiwage-1.1.0-x86_64-linux-gnu.tar.gz
mkdir ~/digiwage
mv ~/digiwage-1.1.0/bin/digiwaged ~/digiwage/digiwaged
mv ~/digiwage-1.1.0/bin/digiwage-cli ~/digiwage/digiwage-cli
rm -rf digiwage-1*


mkdir ~/.digiwage
RPCU=$(pwgen -1 4 -n)
PASS=$(pwgen -1 14 -n)
EXIP=$(hostname -i)

printf "rpcuser=rpc$RPCU\nrpcpassword=$PASS\nrpcport=46103\nrpcthreads=8\nrpcallowip=127.0.0.1\nbind=$EXIP:46003\nmaxconnections=32\ngen=0\nexternalip=$EXIP\ndaemon=1\n\n" > ~/.digiwage/digiwage.conf

~/digiwage/digiwaged -daemon
sleep 60
MKEY=$(~/digiwage/digiwage-cli masternode genkey)

~/digiwage/digiwage-cli stop
printf "masternode=1\nmasternodeprivkey=$MKEY\n\n" >> ~/.digiwage/digiwage.conf
sleep 30

mkdir ~/backup
cp ~/.digiwage/digiwage.conf ~/backup/digiwage.conf
cp ~/.digiwage/wallet.dat ~/backup/wallet.dat

crontab -l > mycron
echo "@reboot ~/digiwage/digiwaged -daemon >/dev/null 2>&1" >> mycron
crontab mycron
rm mycron

echo "Indexing blockchain..."

sleep 1
rm ~/.digiwage/mncache.dat
rm ~/.digiwage/mnpayments.dat
sleep 1
~/digiwage/digiwaged -daemon -reindex
sleep 60

################################################################################


BLKS=$(curl http://144.202.110.14/api/getblockcount)

while true; do
WALLETBLOCKS=$(~/digiwage/digiwage-cli getblockcount)
if (( $(echo "$WALLETBLOCKS < $BLKS" | bc -l) )); then
	clear
	echo " "
	echo " "
	echo "  Keep waiting..."
	echo " "
	echo "    Blocks so far: $WALLETBLOCKS"
	echo " "
	echo " "
	echo " "
	sleep 5
else
	echo " "
	echo " "
	echo "    Complete!"
	echo " "
	echo " "
	sleep 5
	break
fi
	echo " "
	echo " "
	echo " "
done


echo "Now wait for AssetID: 999..."
sleep 1

while true; do

MNSYNC=$(~/digiwage/digiwage-cli mnsync status)
echo "$MNSYNC" > mnwagesync.json
ASSETID=$(jq '.RequestedMasternodeAssets' mnwagesync.json)

if (( $(echo "$ASSETID < 900" | bc -l) )); then
	clear
	echo " "
	echo " "
	echo "  Keep waiting..."
	echo " "
	echo "  Looking for: 999"
	echo "      AssetID: $ASSETID"
	echo " "
	echo " "
	echo " "
	sleep 5
else
	echo " "
	echo " "
	echo "    Complete!"
	echo " "
	echo " "
	sleep 5
	break
fi
	echo " "
	echo " "
	echo " "
done

###########################

rm mnwagesync.json

echo " "
echo " "
echo " "

sleep 2
echo "=================================="
echo " "
echo "Your masternode.conf should look like:"
echo " "
echo "MNxx $EXIP:46003 $MKEY TXID VOUT"
echo " "
echo "=================================="
echo " "

echo " "
sleep 3
echo " "
echo "  - You can now Start Alias in the windows wallet!"
echo " "
echo "       Thanks for using MadStu's Install Script"
echo " "

rm getwageinfo.json
cp ~/.digiwage/masternode.conf ~/backup/masternode.conf

fi
