#!/bin/ash
exit_code
exit_code="$(wget --quiet --tries=1 --spider "http://${HOSTNAME}:8080/sabnzbd/robots.txt" && echo $?)"
if [ "${exit_code}" != 0 ]; then
   echo "HTTP WebUI not responding: Error ${exit_code}"
   exit 1
fi
exit_code="$(wget --quiet --tries=1 --no-check-certificate --spider "https://${HOSTNAME}:9090/sabnzbd/robots.txt" && echo $?)"
if [ "${exit_code}" != 0 ]; then
   echo "HTTPS WebUI not responding: Error ${exit_code}"
   exit 1
fi
echo "WebUIs available"
exit 0