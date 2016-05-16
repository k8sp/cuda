#/bin/bash

# install basic tools
apt-get -y update
apt-get -y install wget git bc make dpkg-dev libssl-dev software-properties-common

# install GCC 4.9
add-apt-repository ppa:ubuntu-toolchain-r/test
apt-get update
apt-get install -y gcc-4.9 g++-4.9

# make GCC 4.9 the default
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 60 --slave /usr/bin/g++ g++ /usr/bin/g++-4.9

# clean apt cache
apt-get clean
