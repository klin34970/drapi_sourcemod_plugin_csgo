#!/bin/bash

# first parameter $1

bzip2 -fvk $1.bsp
bzip2 -fvk $1.nav

curl -T $1.bsp.bz2 ftp://ishot:dx5b3dJ3@master.creeperrepo.net/fastdl/csgo/maps/
curl -T $1.nav.bz2 ftp://ishot:dx5b3dJ3@master.creeperrepo.net/fastdl/csgo/maps/

yes | rm $1.bsp.bz2
yes | rm $1.nav.bz2

exit 0
