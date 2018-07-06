#!/bin/bash
# MadStu's Small Install Script
cd ~
wget https://raw.githubusercontent.com/MadStu/WAGE/master/newwagemn.sh
chmod 777 newwagemn.sh
sed -i -e 's/\r$//' newwagemn.sh
./newwagemn.sh
