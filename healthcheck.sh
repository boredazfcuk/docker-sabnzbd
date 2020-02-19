#!/bin/ash

if [ "$(nc -z "$(hostname -i)" 8080; echo $?)" -ne 0 ]; then
   echo "SABnzbd HTTP WebUI not responding on port 8080"
   exit 1
fi

if [ "$(nc -z "$(hostname -i)" 9090; echo $?)" -ne 0 ]; then
   echo "SABnzbd HTTPS WebUI not responding on port 9090"
   exit 1
fi

echo "SABnzbd HTTP and HTTPS WebUIs responding OK"
exit 0