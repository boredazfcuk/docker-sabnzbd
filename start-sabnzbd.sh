#!/bin/ash

##### Functions #####
Initialise(){
   LANIP="$(hostname -i)"
   N2MBASE="/nzbToMedia"
   N2MREPO="clinton-hall/nzbToMedia"
   echo -e "\n"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ***** Starting sabnzbd/sabnzbd container *****"
   if [ -z "${STACKUSER}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User name not set, defaulting to 'stackman'"; STACKUSER="stackman"; fi
   if [ -z "${STACKPASSWORD}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Password not set, defaulting to 'Skibidibbydibyodadubdub'"; STACKPASSWORD="Skibidibbydibyodadubdub"; fi   
   if [ -z "${UID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User ID not set, defaulting to '1000'"; UID="1000"; fi
   if [ -z "${GROUP}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group name not set, defaulting to 'group'"; GROUP="group"; fi
   if [ -z "${GID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group ID not set, defaulting to '1000'"; GID="1000"; fi
   if [ -z "${MOVIECOMPLETEDIR}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Category complete path not set for movie, defaulting to /storage/downloads/complete/movie/"; MOVIECOMPLETEDIR="/storage/downloads/complete/movie/"; fi
   if [ -z "${MUSICCOMPLETEDIR}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Category complete path not set for music, defaulting to /storage/downloads/complete/music/"; MUSICCOMPLETEDIR="/storage/downloads/complete/music/"; fi
   if [ -z "${OTHERCOMPLETEDIR}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Category complete path not set for other, defaulting to /storage/downloads/complete/other/"; OTHERCOMPLETEDIR="/storage/downloads/complete/other/"; fi
   if [ -z "${TVCOMPLETEDIR}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Category complete path not set for tv, defaulting to /storage/downloads/complete/tv/"; TVCOMPLETEDIR="/storage/downloads/complete/tv/"; fi
   if [ -z "${SABNZBDWATCHDIR}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: NZB file watch path not set, defaulting to /storage/downloads/watch/sabnzbd/"; SABNZBDWATCHDIR="/storage/downloads/watch/sabnzbd/"; fi
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local user: ${STACKUSER}:${UID}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local group: ${GROUP}:${GID}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    SABnzbd application directory: ${SABBASE}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Listening IP Address: ${LANIP}"
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
   if [ -z "$(getent passwd "${STACKUSER}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    User ID available, creating user"
      adduser -s /bin/ash -D -G "${GROUP}" -u "${UID}" "${STACKUSER}"
   elif [ ! "$(getent passwd "${STACKUSER}" | cut -d: -f3)" = "${UID}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   User ID already in use - exiting"
      exit 1
   fi
}

FirstRun(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    First run detected - create default config"
   find "${CONFIGDIR}" ! -user "${STACKUSER}" -exec chown "${STACKUSER}" {} \;
   find "${CONFIGDIR}" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
   su -m "${STACKUSER}" -c "python ${SABBASE}/SABnzbd.py --config-file ${CONFIGDIR}/sabnzbd.ini --daemon --pidfile /tmp/sabnzbd.pid --browser 0"
   sleep 15
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ***** Reload sabnzbd/sabnzbd *****"
   pkill python
   sleep 5
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Customise SABnzbd config"
   sed -i \
      -e "/^\[misc\]/,/^\[.*\]/ s%^fast_fail = 0%fast_fail = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^safe_postproc = 0%safe_postproc = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^empty_postproc = 0%empty_postproc = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^notified_new_skin =.*%notified_new_skin = 2%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^fail_hopeless_jobs = .*%fail_hopeless_jobs = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^web_color =.*%web_color = gold%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^inet_exposure =.*%inet_exposure = 0%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^disable_api_key =.*%disable_api_key = 0%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^enable_7zip = .*%enable_7zip = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^warn_empty_nzb =.*%warn_empty_nzb = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^enable_bonjour =.*%enable_bonjour = 0%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^enable_unzip =.*%enable_unzip = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^port =.*%port = 8080%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^show_sysload =.*%show_sysload = 2%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^no_dupes =.*%no_dupes = 3%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^ignore_samples =.*%ignore_samples = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^html_login =.*%html_login = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^no_series_dupes =.*%no_series_dupes = 3%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^propagation_delay =.*%propagation_delay = 15%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^sfv_check =.*%sfv_check = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^movie_categories = .*%movie_categories = movie,%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^tv_categories =.*%tv_categories = tv,%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^fast_fail =.*%fast_fail = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^dirscan_speed =.*%dirscan_speed = 60%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^pre_check =.*%pre_check = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^web_dir =.*%web_dir = Plush%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^download_free =.*%download_free = 80G%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^par_option =.*%par_option = -N -t%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^pause_on_pwrar =.*%pause_on_pwrar = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^movie_categories =.*%movie_categories = movie,%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^replace_spaces =.*%replace_spaces = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^replace_dots =.*%replace_dots = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^sanitize_safe =.*%sanitize_safe = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^direct_unpack =.*%direct_unpack = 0%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^direct_unpack_tested =.*%direct_unpack_tested = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^warn_dupl_jobs =.*%warn_dupl_jobs = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^enable_par_cleanup =.*%enable_par_cleanup = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^flat_unpack =.*%flat_unpack = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^script_can_fail =.*%script_can_fail = 0%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^history_retention =.*%history_retention = 7d%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^ipv6_servers =.*%ipv6_servers = 0%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^ignore_empty_files =.*%ignore_empty_files = 1%" \
      "${CONFIGDIR}/sabnzbd.ini"
   sleep 1
}

EnableSSL(){
   if [ ! -d "${CONFIGDIR}/https" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure HTTPS"
      mkdir -p "${CONFIGDIR}/https"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Generate server key"
      openssl ecparam -genkey -name secp384r1 -out "${CONFIGDIR}/https/sabnzbd.key"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Generate certificate request"
      openssl req -new -subj "/C=NA/ST=Global/L=Global/O=SABnzbd/OU=SABnzbd/CN=SABnzbd/" -key "${CONFIGDIR}/https/sabnzbd.key" -out "${CONFIGDIR}/https/sabnzbd.csr"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Generate certificate"
      openssl x509 -req -sha256 -days 3650 -in "${CONFIGDIR}/https/sabnzbd.csr" -signkey "${CONFIGDIR}/https/sabnzbd.key" -out "${CONFIGDIR}/https/sabnzbd.crt" >/dev/null 2>&1
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Enable HTTPS"
      sed -i \
         -e "/^\[misc\]/,/^\[.*\]/ s%^https_key =.*%https_key = ${CONFIGDIR}/https/sabnzbd.key%" \
         -e "/^\[misc\]/,/^\[.*\]/ s%^https_cert =.*%https_cert = ${CONFIGDIR}/https/sabnzbd.crt%" \
         -e "/^\[misc\]/,/^\[.*\]/ s%^enable_https =.*%enable_https = 1%" \
         -e "/^\[misc\]/,/^\[.*\]/ s%^https_port =.*%https_port = 9090%" \
         "${CONFIGDIR}/sabnzbd.ini"
   fi
}

Configure(){
   sed -i \
      -e "/^\[misc\]/,/^\[.*\]/ s%^host =.*%host = ${LANIP}%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^username = \".*\"%username = \"${STACKUSER}\"%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^password = \".*\"%password = \"${STACKPASSWORD}\"%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^dirscan_dir =.*%dirscan_dir = ${SABNZBDWATCHDIR}%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^download_dir =.*%download_dir = ${SABNZBDINCOMINGDIR}%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^nzb_backup_dir =.*%nzb_backup_dir = ${SABNZBDFILEBACKUPDIR}%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^complete_dir =.*%complete_dir = ${OTHERCOMPLETEDIR}%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^script_dir =.*%script_dir = ${N2MBASE}%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^api_key =.*%api_key = ${GLOBALAPIKEY}%" \
      -e "/^\[\[movie\]\]/,/^\[.*\]/ s%^dir =.*%dir = ${MOVIECOMPLETEDIR}%" \
      -e "/^\[\[movie\]\]/,/^\[.*\]/ s%^name =.*%name = movie%" \
      -e "/^\[\[movie\]\]/,/^\[.*\]/ s%^script =.*%script = nzbToCouchPotato.py%" \
      -e "/^\[\[movie\]\]/,/^\[.*\]/ s%^priority =.*%priority = 2%" \
      -e "/^\[\[music\]\]/,/^\[.*\]/ s%^dir =.*%dir = ${MUSICCOMPLETEDIR}%" \
      -e "/^\[\[music\]\]/,/^\[.*\]/ s%^name =.*%name = music%" \
      -e "/^\[\[music\]\]/,/^\[.*\]/ s%^script =.*%script = nzbToHeadPhones.py%" \
      -e "/^\[\[music\]\]/,/^\[.*\]/ s%^priority =.*%priority = 2%" \
      -e "/^\[\[tv\]\]/,/^\[.*\]/ s%^dir =.*%dir = ${TVCOMPLETEDIR}%" \
      -e "/^\[\[tv\]\]/,/^\[.*\]/ s%^name =.*%name = tv%" \
      -e "/^\[\[tv\]\]/,/^\[.*\]/ s%^script =.*%script = nzbToSickBeard.py%" \
      -e "/^\[\[tv\]\]/,/^\[.*\]/ s%^priority =.*%priority = 2%" \
      "${CONFIGDIR}/sabnzbd.ini"
   if [ ! -z "${MEDIAACCESSDOMAIN}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Access domain: ${MEDIAACCESSDOMAIN}"
      HOSTWHITELIST="$(sed -nr '/\[misc\]/,/\[/{/^host_whitelist =/p}' "${CONFIGDIR}/sabnzbd.ini")"
      if [ "$(grep -c "${MEDIAACCESSDOMAIN}" "${CONFIGDIR}/sabnzbd.ini")" = 0 ]; then
         sed -i \
            -e "s%^${HOSTWHITELIST}$%${HOSTWHITELIST} ${MEDIAACCESSDOMAIN},%" \
            "${CONFIGDIR}/sabnzbd.ini"
      fi
   else
      echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Access domain not set, SABnzbd will only be accessible by IP address"
   fi
}

InstallnzbToMedia(){
   if [ ! -d "${N2MBASE}" ]; then
      mkdir -p "${N2MBASE}"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ${N2MREPO} not detected, installing..."
      chown "${STACKUSER}":"${GROUP}" "${N2MBASE}"
      cd "${N2MBASE}"
      su "${STACKUSER}" -c "git clone --quiet --branch master https://github.com/${N2MREPO}.git ${N2MBASE}"
      if [ ! -f "${N2MBASE}/autoProcessMedia.cfg" ]; then
         cp "${N2MBASE}/autoProcessMedia.cfg.spec" "${N2MBASE}/autoProcessMedia.cfg"
      fi
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Change nzbToMedia default configuration"
      sed -i \
         -e "/^\[General\]/,/^\[.*\]/ s%auto_update =.*%auto_update = 1%" \
         -e "/^\[General\]/,/^\[.*\]/ s%git_path =.*%git_path = /usr/bin/git%" \
         -e "/^\[General\]/,/^\[.*\]/ s%git_branch =.*%git_branch = master%" \
         -e "/^\[General\]/,/^\[.*\]/ s%ffmpeg_path = *%ffmpeg_path = /usr/local/bin/ffmpeg%" \
         -e "/^\[General\]/,/^\[.*\]/ s%safe_mode =.*%safe_mode = 1%" \
         -e "/^\[General\]/,/^\[.*\]/ s%no_extract_failed =.*%no_extract_failed = 1%" \
         "${N2MBASE}/autoProcessMedia.cfg"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure nzbToMedia SABnzbd settings"
      sed -i \
         -e "/^\[Nzb\]/,/^\[.*\]/ s%clientAgent =.*%clientAgent = sabnzbd%" \
         -e "/^\[Nzb\]/,/^\[.*\]/ s%sabnzbd_host =.*%sabnzbd_host = http://openvpnpia%" \
         -e "/^\[Nzb\]/,/^\[.*\]/ s%sabnzbd_port.*%sabnzbd_port = 8080%" \
         -e "/^\[Nzb\]/,/^\[.*\]/ s%sabnzbd_apikey =.*%sabnzbd_apikey = ${GLOBALAPIKEY}%" \
         "${N2MBASE}/autoProcessMedia.cfg"
      if [ ! -z "${COUCHPOTATOENABLED}" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure nzbToMedia CouchPotato settings"
         sed -i \
            -e "/^\[CouchPotato\]/,/^\[.*\]/ s%enabled = .*%enabled = 1%" \
            -e "/^\[CouchPotato\]/,/^\[.*\]/ s%apikey =.*%apikey = ${GLOBALAPIKEY}%" \
            -e "/^\[CouchPotato\]/,/^\[.*\]/ s%host =.*%host = openvpnpia%" \
            -e "/^\[CouchPotato\]/,/^\[.*\]/ s%port =.*%port = 5050%" \
            -e "/^\[CouchPotato\]/,/^\[.*\]/ s%ssl =.*%ssl = 1%" \
            -e "/^\[CouchPotato\]/,/^\[.*\]/ s%web_root =.*%web_root = /couchpotato%" \
            "${N2MBASE}/autoProcessMedia.cfg"
      fi
      if [ ! -z "${SICKGEARENABLED}" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure nzbToMedia SickGear settings"
         sed -i \
            -e "/^\[SickBeard\]/,/^\[.*\]/ s%enabled = .*%enabled = 1%" \
            -e "/^\[SickBeard\]/,/^\[.*\]/ s%apikey =.*%apikey = ${GLOBALAPIKEY}%" \
            -e "/^\[SickBeard\]/,/^\[.*\]/ s%host =.*%host = openvpnpia%" \
            -e "/^\[SickBeard\]/,/^\[.*\]/ s%port =.*%port = 8081%" \
            -e "/^\[SickBeard\]/,/^\[.*\]/ s%ssl =.*%ssl = 1%" \
            -e "/^\[SickBeard\]/,/^\[.*\]/ s%fork =.*%fork = sickgear%" \
            -e "/^\[SickBeard\]/,/^\[.*\]/ s%web_root =.*%web_root = /sickgear%" \
            "${N2MBASE}/autoProcessMedia.cfg"
      fi
      if [ ! -z "${HEADPHONESENABLED}" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure nzbToMedia Headphones settings"
         sed -i \
            -e "/^\[HeadPhones\]/,/^\[.*\]/ s%enabled = .*%enabled = 1%" \
            -e "/^\[HeadPhones\]/,/^\[.*\]/ s%apikey =.*%apikey = ${GLOBALAPIKEY}%" \
            -e "/^\[HeadPhones\]/,/^\[.*\]/ s%host =.*%host = openvpnpia%" \
            -e "/^\[HeadPhones\]/,/^\[.*\]/ s%port =.*%port = 8181%" \
            -e "/^\[HeadPhones\]/,/^\[.*\]/ s%ssl =.*%ssl = 1%" \
            -e "/^\[HeadPhones\]/,/^\[.*\]/ s%web_root =.*%web_root = /headphones%" \
            "${N2MBASE}/autoProcessMedia.cfg"
      fi
   fi
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure nzbToMedia download paths"
   sed -i \
      -e "/^\[CouchPotato\]/,/^\[.*\]/ s%watch_dir =.*%watch_dir = ${MOVIECOMPLETEDIR}%" \
      -e "/^\[SickBeard\]/,/^\[.*\]/ s%watch_dir =.*%watch_dir = ${TVCOMPLETEDIR}%" \
      -e "/^\[Headphones\]/,/^\[.*\]/ s%watch_dir =.*%watch_dir = ${MUSICCOMPLETEDIR}%" \
      -e "/^\[Nzb\]/,/^\[.*\]/ s%default_downloadDirectory =.*%default_downloadDirectory = ${OTHERCOMPLETEDIR}%" \
      "${N2MBASE}/autoProcessMedia.cfg"
}

SetOwnerAndGroup(){
   DIRSCANDIR="$(grep dirscan_dir "${CONFIGDIR}/sabnzbd.ini" | awk '{print $3}')"
   DOWNLOADDIR="$(grep download_dir "${CONFIGDIR}/sabnzbd.ini" | awk '{print $3}')"
   COMPLETEDIR="$(grep complete_dir "${CONFIGDIR}/sabnzbd.ini" | awk '{print $3}')"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Correct owner and group of syncronised files, if required"
   find "${CONFIGDIR}" ! -user "${STACKUSER}" -exec chown "${STACKUSER}" {} \;
   find "${CONFIGDIR}" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
   find "${SABBASE}" ! -user "${STACKUSER}" -exec chown "${STACKUSER}" {} \;
   find "${SABBASE}" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
   find "${N2MBASE}" ! -user "${STACKUSER}" -exec chown "${STACKUSER}" {} \;
   find "${N2MBASE}" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
   if [ ! -z "${DIRSCANDIR}" ] && [ -d "${DIRSCANDIR}" ]; then
      find "${DIRSCANDIR}" -type d ! -user "${STACKUSER}" -exec chown "${STACKUSER}" {} \;
   fi
   if [ ! -z "${DOWNLOADDIR}" ] && [ -d "${DOWNLOADDIR}" ]; then
      find "${DOWNLOADDIR}" -type d ! -user "${STACKUSER}" -exec chown "${STACKUSER}" {} \;
   fi
   if [ ! -z "${COMPLETEDIR}" ] && [ -d "${COMPLETEDIR}" ]; then
      find "${COMPLETEDIR}"  -type d ! -user "${STACKUSER}" -exec chown "${STACKUSER}" {} \;
   fi
}

LaunchSABnzbd(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Starting SABnzbd as ${STACKUSER}"
   su "${STACKUSER}" -c "python ${SABBASE}/SABnzbd.py --config-file ${CONFIGDIR}/sabnzbd.ini --browser 0"
}

##### Script #####
Initialise
CreateGroup
CreateUser
if [ ! -d "${CONFIGDIR}/admin" ]; then FirstRun; fi
EnableSSL
Configure
InstallnzbToMedia
SetOwnerAndGroup
LaunchSABnzbd