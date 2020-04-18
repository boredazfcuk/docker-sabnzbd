#!/bin/ash

if [ "$(netstat -plnt | grep -c 8080)" -ne 1 ]; then
   echo "SABnzbd HTTP WebUI not responding on port 8080"
   exit 1
fi

if [ "$(netstat -plnt | grep -c 9090)" -ne 1 ]; then
   echo "SABnzbd HTTPS WebUI not responding on port 9090"
   exit 1
fi

echo "SABnzbd HTTP and HTTPS WebUIs responding OK"
exit 0