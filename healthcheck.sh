#!/bin/ash
EXIT_CODE
EXIT_CODE="$(wget --quiet --tries=1 --spider "http://${HOSTNAME}:8080/sabnzbd/robots.txt" && echo $?)"
if [ "${EXIT_CODE}" != 0 ]; then
   echo "HTTP WebUI not responding: Error ${EXIT_CODE}"
   exit 1
fi
EXIT_CODE="$(wget --quiet --tries=1 --no-check-certificate --spider "https://${HOSTNAME}:9090/sabnzbd/robots.txt" && echo $?)"
if [ "${EXIT_CODE}" != 0 ]; then
   echo "HTTPS WebUI not responding: Error ${EXIT_CODE}"
   exit 1
fi
echo "WebUIs available"
exit 0