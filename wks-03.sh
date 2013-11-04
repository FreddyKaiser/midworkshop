#!/bin/sh
#
# Workshop script for radius client calls

echo "User-Name=+41798440457" | radclient -t 120 localhost auth TestingRadius@cartel.ch
echo "User-Name=+41798440457,User-Password=''" | radclient -t 120 localhost auth TestingRadius@cartel.ch

#==========================================================
