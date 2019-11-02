#!/bin/ash
wget --quiet --tries=1 --no-check-certificate --spider "http://${HOSTNAME}:8080/sabnzbd" || exit 1
wget --quiet --tries=1 --no-check-certificate --spider "https://${HOSTNAME}:9090/sabnzbd" || exit 1
exit 0