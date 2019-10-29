#!/bin/ash

##### Functions #####
Initialise(){
   LANIP="$(hostname -i)"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ***** Starting sabnzbd/sabnzbd container *****"
   if [ -z "${USER}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User name not set, defaulting to 'user'"; USER="user"; fi
   if [ -z "${UID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User ID not set, defaulting to '1000'"; UID="1000"; fi
   if [ -z "${GROUP}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group name not set, defaulting to 'group'"; GROUP="group"; fi
   if [ -z "${GID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group ID not set, defaulting to '1000'"; GID="1000"; fi
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local user: ${USER}:${UID}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local group: ${GROUP}:${GID}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    SABnzbd application directory: ${SABBASE}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Listening IP Address: ${LANIP}"
   SABNZBDHOST="$(sed -nr '/\[misc\]/,/\[/{/^host =/p}' "${CONFIGDIR}/sabnzbd.ini")"
   sed -i "s%^${SABNZBDHOST}$%host = ${LANIP}%" "${CONFIGDIR}/sabnzbd.ini"
}

CreateGroup(){
   if [ -z "$(getent group "${GROUP}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Group ID available, creating group"
      addgroup -g "${GID}" "${GROUP}"
   elif [ ! "$(getent group "${GROUP}" | cut -d: -f3)" = "${GID}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   Group GID mismatch - exiting"
      exit 1
   fi
}

CreateUser(){
   if [ -z "$(getent passwd "${USER}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    User ID available, creating user"
      adduser -s /bin/ash -D -G "${GROUP}" -u "${UID}" "${USER}"
   elif [ ! "$(getent passwd "${USER}" | cut -d: -f3)" = "${UID}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   User ID already in use - exiting"
      exit 1
   fi
}

SetOwnerAndGroup(){
   DIRSCANDIR="$(grep dirscan_dir "${CONFIGDIR}/sabnzbd.ini" | awk '{print $3}')"
   DOWNLOADDIR="$(grep download_dir "${CONFIGDIR}/sabnzbd.ini" | awk '{print $3}')"
   COMPLETEDIR="$(grep complete_dir "${CONFIGDIR}/sabnzbd.ini" | awk '{print $3}')"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Correct owner and group of syncronised files, if required"
   find "${CONFIGDIR}" ! -user "${USER}" -exec chown "${USER}" {} \;
   find "${CONFIGDIR}" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
   find "${SABBASE}" ! -user "${USER}" -exec chown "${USER}" {} \;
   find "${SABBASE}" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
   find "${N2MBASE}" ! -user "${USER}" -exec chown "${USER}" {} \;
   find "${N2MBASE}" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
   if [ ! -z "${DIRSCANDIR}" ] && [ -d "${DIRSCANDIR}" ]; then
      find "${DIRSCANDIR}" -type d ! -user "${USER}" -exec chown "${USER}" {} \;
   fi
   if [ ! -z "${DOWNLOADDIR}" ] && [ -d "${DOWNLOADDIR}" ]; then
      find "${DOWNLOADDIR}" -type d ! -user "${USER}" -exec chown "${USER}" {} \;
   fi
   if [ ! -z "${COMPLETEDIR}" ] && [ -d "${COMPLETEDIR}" ]; then
      find "${COMPLETEDIR}"  -type d ! -user "${USER}" -exec chown "${USER}" {} \;
   fi
}

InstallnzbToMedia(){
   if [ ! -d "${N2MBASE}/.git" ]; then
      echo "$(date '+%H:%M:%S') [INFO    ][deluge.launcher.docker        :${PID}] ${N2MREPO} not detected, installing..."
      chown "${USER}":"${GROUP}" "${N2MBASE}"
      cd "${N2MBASE}"
      su "${USER}" -c "git clone -b master https://github.com/${N2MREPO}.git ${N2MBASE}"
      if [ -f "/shared/autoProcessMedia.cfg" ]; then ln -s "/shared/autoProcessMedia.cfg" "${N2MBASE}/autoProcessMedia.cfg"; fi
   fi
}

LaunchSABnzbd(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Starting SABnzbd as ${USER}"
   su "${USER}" -c 'python '"${SABBASE}/SABnzbd.py"' -f '"${CONFIGDIR}/sabnzbd.ini"' -b0'
}

##### Script #####
Initialise
CreateGroup
CreateUser
SetOwnerAndGroup
InstallnzbToMedia
LaunchSABnzbd