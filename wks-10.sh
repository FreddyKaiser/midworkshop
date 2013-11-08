#!/bin/sh
#
# Workshop script for radius client calls
# <radiusport> <msisdn> <optionalPassword>

echo "User-Name=$2,User-Password='$3'" | radclient -t 120 178.209.52.189:$1 auth thisMustStaySecret

#==========================================================
