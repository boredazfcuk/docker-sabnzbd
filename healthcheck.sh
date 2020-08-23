#!/bin/ash

if [ "$(netstat -plnt | grep -c 9090)" -ne 1 ]; then
   echo "SABnzbd HTTP WebUI not responding on port 9090"
   exit 1
fi

if [ "$(hostname -i 2>/dev/null | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | wc -l)" -eq 0 ]; then
   echo "NIC missing"
   exit 1
fi

echo "SABnzbd HTTP WebUIs responding OK"
exit 0