#!/bin/bash
set -e
if [ -z "$1" ]
then 
echo "The first argument should be the role, the second the master"
exit
fi
if [ -n "$1" ]
then
ROLE=$1
MASTER=$2
fi
if [ `lsb_release -cs` == "jessie" ]; then
wget -O - https://repo.saltstack.com/apt/debian/8/amd64/latest/SALTSTACK-GPG-KEY.pub | apt-key add -
echo 'deb http://repo.saltstack.com/apt/debian/8/amd64/latest jessie main' > /etc/apt/sources.list.d/salt.list
fi
if [ `lsb_release -cs` == "xenial" ]; then
wget -O - https://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest/SALTSTACK-GPG-KEY.pub | apt-key add -
echo 'deb http://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest xenial main' > /etc/apt/sources.list.d/salt.list
fi
apt-get update -y
apt-get install salt-minion -y
echo "role: $ROLE" >> /etc/salt/grains
echo "master: $MASTER" >> /etc/salt/minion
service salt-minion restart
