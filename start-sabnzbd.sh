#!/bin/ash

##### Functions #####
Initialise(){
   lan_ip="$(hostname -i)"
   nzb2media_base_dir="/nzbToMedia"
   nzb2media_repo="clinton-hall/nzbToMedia"
   echo -e "\n"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ***** Starting sabnzbd/sabnzbd container *****"
   if [ -z "${stack_user}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User name not set, defaulting to 'stackman'"; stack_user="stackman"; fi
   if [ -z "${stack_password}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Password not set, defaulting to 'Skibidibbydibyodadubdub'"; stack_password="Skibidibbydibyodadubdub"; fi   
   if [ -z "${user_id}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User ID not set, defaulting to '1000'"; user_id="1000"; fi
   if [ -z "${group}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group name not set, defaulting to 'group'"; group="group"; fi
   if [ -z "${group_id}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group ID not set, defaulting to '1000'"; group_id="1000"; fi
   if [ -z "${movie_complete_dir}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Category complete path not set for movie, defaulting to /storage/downloads/complete/movie/"; movie_complete_dir="/storage/downloads/complete/movie/"; fi
   if [ -z "${music_complete_dir}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Category complete path not set for music, defaulting to /storage/downloads/complete/music/"; music_complete_dir="/storage/downloads/complete/music/"; fi
   if [ -z "${other_complete_dir}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Category complete path not set for other, defaulting to /storage/downloads/complete/other/"; other_complete_dir="/storage/downloads/complete/other/"; fi
   if [ -z "${tv_complete_dir}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Category complete path not set for tv, defaulting to /storage/downloads/complete/tv/"; tv_complete_dir="/storage/downloads/complete/tv/"; fi
   if [ -z "${sabnzbd_watch_dir}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: NZB file watch path not set, defaulting to /storage/downloads/watch/sabnzbd/"; sabnzbd_watch_dir="/storage/downloads/watch/sabnzbd/"; fi
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local user: ${stack_user}:${user_id}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local group: ${group}:${group_id}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    SABnzbd application directory: ${app_base_dir}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Listening IP Address: ${lan_ip}"
}

CreateGroup(){
   if [ -z "$(getent group "${group}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Group ID available, creating group"
      addgroup -g "${group_id}" "${group}"
   elif [ ! "$(getent group "${group}" | cut -d: -f3)" = "${group_id}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   Group group_id mismatch - exiting"
      exit 1
   fi
}

CreateUser(){
   if [ -z "$(getent passwd "${stack_user}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    User ID available, creating user"
      adduser -s /bin/ash -D -G "${group}" -u "${user_id}" "${stack_user}"
   elif [ ! "$(getent passwd "${stack_user}" | cut -d: -f3)" = "${user_id}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   User ID already in use - exiting"
      exit 1
   fi
}

FirstRun(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    First run detected - create default config"
   find "${config_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${config_dir}" ! -group "${group}" -exec chgrp "${group}" {} \;
   su -m "${stack_user}" -c "python ${app_base_dir}/SABnzbd.py --config-file ${config_dir}/sabnzbd.ini --daemon --pidfile /tmp/sabnzbd.pid --browser 0"
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
      "${config_dir}/sabnzbd.ini"
   sleep 1
}

EnableSSL(){
   if [ ! -d "${config_dir}/https" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure HTTPS"
      mkdir -p "${config_dir}/https"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Generate server key"
      openssl ecparam -genkey -name secp384r1 -out "${config_dir}/https/sabnzbd.key"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Generate certificate request"
      openssl req -new -subj "/C=NA/ST=Global/L=Global/O=SABnzbd/OU=SABnzbd/CN=SABnzbd/" -key "${config_dir}/https/sabnzbd.key" -out "${config_dir}/https/sabnzbd.csr"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Generate certificate"
      openssl x509 -req -sha256 -days 3650 -in "${config_dir}/https/sabnzbd.csr" -signkey "${config_dir}/https/sabnzbd.key" -out "${config_dir}/https/sabnzbd.crt" >/dev/null 2>&1
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Enable HTTPS"
      sed -i \
         -e "/^\[misc\]/,/^\[.*\]/ s%^https_key =.*%https_key = ${config_dir}/https/sabnzbd.key%" \
         -e "/^\[misc\]/,/^\[.*\]/ s%^https_cert =.*%https_cert = ${config_dir}/https/sabnzbd.crt%" \
         -e "/^\[misc\]/,/^\[.*\]/ s%^enable_https =.*%enable_https = 1%" \
         -e "/^\[misc\]/,/^\[.*\]/ s%^https_port =.*%https_port = 9090%" \
         "${config_dir}/sabnzbd.ini"
   fi
}

Configure(){
   sed -i \
      -e "/^\[misc\]/,/^\[.*\]/ s%^host =.*%host = ${lan_ip}%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^username = \".*\"%username = \"${stack_user}\"%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^password = \".*\"%password = \"${stack_password}\"%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^dirscan_dir =.*%dirscan_dir = ${sabnzbd_watch_dir}%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^download_dir =.*%download_dir = ${sabnzbd_incoming_dir}%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^nzb_backup_dir =.*%nzb_backup_dir = ${sabnzbd_file_backup_dir}%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^complete_dir =.*%complete_dir = ${other_complete_dir}%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^script_dir =.*%script_dir = ${nzb2media_base_dir}%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^api_key =.*%api_key = ${global_api_key}%" \
      -e "/^\[\[movie\]\]/,/^\[.*\]/ s%^dir =.*%dir = ${movie_complete_dir}%" \
      -e "/^\[\[movie\]\]/,/^\[.*\]/ s%^name =.*%name = movie%" \
      -e "/^\[\[movie\]\]/,/^\[.*\]/ s%^script =.*%script = nzbToCouchPotato.py%" \
      -e "/^\[\[movie\]\]/,/^\[.*\]/ s%^priority =.*%priority = 2%" \
      -e "/^\[\[music\]\]/,/^\[.*\]/ s%^dir =.*%dir = ${music_complete_dir}%" \
      -e "/^\[\[music\]\]/,/^\[.*\]/ s%^name =.*%name = music%" \
      -e "/^\[\[music\]\]/,/^\[.*\]/ s%^script =.*%script = nzbToHeadPhones.py%" \
      -e "/^\[\[music\]\]/,/^\[.*\]/ s%^priority =.*%priority = 2%" \
      -e "/^\[\[tv\]\]/,/^\[.*\]/ s%^dir =.*%dir = ${tv_complete_dir}%" \
      -e "/^\[\[tv\]\]/,/^\[.*\]/ s%^name =.*%name = tv%" \
      -e "/^\[\[tv\]\]/,/^\[.*\]/ s%^script =.*%script = nzbToSickBeard.py%" \
      -e "/^\[\[tv\]\]/,/^\[.*\]/ s%^priority =.*%priority = 2%" \
      "${config_dir}/sabnzbd.ini"
   if [ "${sabnzbd_server_host}" ] && [ "${sabnzbd_server_host_port}" ] && [ "${sabnzbd_server_host_ssl}" ] && [ "${sabnzbd_server_host_user}" ] && [ "${sabnzbd_server_host_password}" ] && [ "${sabnzbd_server_host_connections}" ] && [ "${sabnzbd_server_host_priority}" ]; then
      sed -i \
         -e "/^\[\[UsenetHost\]\]/,/^\[.*\]/ s%^username =.*%username = ${sabnzbd_server_host_user}%" \
         -e "/^\[\[UsenetHost\]\]/,/^\[.*\]/ s%^displayname =.*%displayname = UsenetHost%" \
         -e "/^\[\[UsenetHost\]\]/,/^\[.*\]/ s%^name =.*%name = UsenetHost%" \
         -e "/^\[\[UsenetHost\]\]/,/^\[.*\]/ s%^password =.*%password = ${sabnzbd_server_host_password}%" \
         -e "/^\[\[UsenetHost\]\]/,/^\[.*\]/ s%^connections =.*%connections = ${sabnzbd_server_host_connections}%" \
         -e "/^\[\[UsenetHost\]\]/,/^\[.*\]/ s%^host =.*%host = ${sabnzbd_server_host}%" \
         -e "/^\[\[UsenetHost\]\]/,/^\[.*\]/ s%^port =.*%port = ${sabnzbd_server_host_port}%" \
         -e "/^\[\[UsenetHost\]\]/,/^\[.*\]/ s%^ssl =.*%ssl = ${sabnzbd_server_host_ssl}%" \
         -e "/^\[\[UsenetHost\]\]/,/^\[.*\]/ s%^priority =.*%priority = ${sabnzbd_server_host_priority}%" \
      "${config_dir}/sabnzbd.ini"
   fi
   if [ "${media_access_domain}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Access domain: ${media_access_domain}"
      host_verification_access_list="$(sed -nr '/\[misc\]/,/\[/{/^host_whitelist =/p}' "${config_dir}/sabnzbd.ini")"
      if [ "$(grep -c "${media_access_domain}" "${config_dir}/sabnzbd.ini")" = 0 ]; then
         sed -i \
            -e "s%^${host_verification_access_list}$%${host_verification_access_list} ${media_access_domain},%" \
            "${config_dir}/sabnzbd.ini"
      fi
   else
      echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Access domain not set, SABnzbd will only be accessible by IP address"
   fi
}

InstallnzbToMedia(){
   if [ ! -d "${nzb2media_base_dir}" ]; then
      mkdir -p "${nzb2media_base_dir}"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    ${nzb2media_repo} not detected, installing..."
      chown "${stack_user}":"${group}" "${nzb2media_base_dir}"
      cd "${nzb2media_base_dir}"
      su "${stack_user}" -c "git clone --quiet --branch master https://github.com/${nzb2media_repo}.git ${nzb2media_base_dir}"
      if [ ! -f "${nzb2media_base_dir}/autoProcessMedia.cfg" ]; then
         cp "${nzb2media_base_dir}/autoProcessMedia.cfg.spec" "${nzb2media_base_dir}/autoProcessMedia.cfg"
      fi
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Change nzbToMedia default configuration"
      sed -i \
         -e "/^\[General\]/,/^\[.*\]/ s%auto_update =.*%auto_update = 1%" \
         -e "/^\[General\]/,/^\[.*\]/ s%git_path =.*%git_path = /usr/bin/git%" \
         -e "/^\[General\]/,/^\[.*\]/ s%git_branch =.*%git_branch = master%" \
         -e "/^\[General\]/,/^\[.*\]/ s%ffmpeg_path = *%ffmpeg_path = /usr/local/bin/ffmpeg%" \
         -e "/^\[General\]/,/^\[.*\]/ s%safe_mode =.*%safe_mode = 1%" \
         -e "/^\[General\]/,/^\[.*\]/ s%no_extract_failed =.*%no_extract_failed = 1%" \
         "${nzb2media_base_dir}/autoProcessMedia.cfg"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure nzbToMedia SABnzbd settings"
      sed -i \
         -e "/^\[Nzb\]/,/^\[.*\]/ s%clientAgent =.*%clientAgent = sabnzbd%" \
         -e "/^\[Nzb\]/,/^\[.*\]/ s%sabnzbd_host =.*%sabnzbd_host = http://openvpnpia%" \
         -e "/^\[Nzb\]/,/^\[.*\]/ s%sabnzbd_port.*%sabnzbd_port = 8080%" \
         -e "/^\[Nzb\]/,/^\[.*\]/ s%sabnzbd_apikey =.*%sabnzbd_apikey = ${global_api_key}%" \
         "${nzb2media_base_dir}/autoProcessMedia.cfg"
      if [ "${couchpotato_enabled}" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure nzbToMedia CouchPotato settings"
         sed -i \
            -e "/^\[CouchPotato\]/,/^\[.*\]/ s%enabled = .*%enabled = 1%" \
            -e "/^\[CouchPotato\]/,/^\[.*\]/ s%apikey =.*%apikey = ${global_api_key}%" \
            -e "/^\[CouchPotato\]/,/^\[.*\]/ s%host =.*%host = openvpnpia%" \
            -e "/^\[CouchPotato\]/,/^\[.*\]/ s%port =.*%port = 5050%" \
            -e "/^\[CouchPotato\]/,/^\[.*\]/ s%ssl =.*%ssl = 1%" \
            -e "/^\[CouchPotato\]/,/^\[.*\]/ s%web_root =.*%web_root = /couchpotato%" \
            "${nzb2media_base_dir}/autoProcessMedia.cfg"
      fi
      if [ "${sickgear_enabled}" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure nzbToMedia SickGear settings"
         sed -i \
            -e "/^\[SickBeard\]/,/^\[.*\]/ s%enabled = .*%enabled = 1%" \
            -e "/^\[SickBeard\]/,/^\[.*\]/ s%apikey =.*%apikey = ${global_api_key}%" \
            -e "/^\[SickBeard\]/,/^\[.*\]/ s%host =.*%host = openvpnpia%" \
            -e "/^\[SickBeard\]/,/^\[.*\]/ s%port =.*%port = 8081%" \
            -e "/^\[SickBeard\]/,/^\[.*\]/ s%ssl =.*%ssl = 1%" \
            -e "/^\[SickBeard\]/,/^\[.*\]/ s%fork =.*%fork = sickgear%" \
            -e "/^\[SickBeard\]/,/^\[.*\]/ s%web_root =.*%web_root = /sickgear%" \
            "${nzb2media_base_dir}/autoProcessMedia.cfg"
      fi
      if [ "${headphones_enabled}" ]; then
         echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure nzbToMedia Headphones settings"
         sed -i \
            -e "/^\[HeadPhones\]/,/^\[.*\]/ s%enabled = .*%enabled = 1%" \
            -e "/^\[HeadPhones\]/,/^\[.*\]/ s%apikey =.*%apikey = ${global_api_key}%" \
            -e "/^\[HeadPhones\]/,/^\[.*\]/ s%host =.*%host = openvpnpia%" \
            -e "/^\[HeadPhones\]/,/^\[.*\]/ s%port =.*%port = 8181%" \
            -e "/^\[HeadPhones\]/,/^\[.*\]/ s%ssl =.*%ssl = 1%" \
            -e "/^\[HeadPhones\]/,/^\[.*\]/ s%web_root =.*%web_root = /headphones%" \
            "${nzb2media_base_dir}/autoProcessMedia.cfg"
      fi
   fi
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Configure nzbToMedia download paths"
   sed -i \
      -e "/^\[CouchPotato\]/,/^\[.*\]/ s%watch_dir =.*%watch_dir = ${movie_complete_dir}%" \
      -e "/^\[SickBeard\]/,/^\[.*\]/ s%watch_dir =.*%watch_dir = ${tv_complete_dir}%" \
      -e "/^\[Headphones\]/,/^\[.*\]/ s%watch_dir =.*%watch_dir = ${music_complete_dir}%" \
      -e "/^\[Nzb\]/,/^\[.*\]/ s%default_downloadDirectory =.*%default_downloadDirectory = ${other_complete_dir}%" \
      "${nzb2media_base_dir}/autoProcessMedia.cfg"
}

SetOwnerAndGroup(){
   sabnzbd_watch_dir="$(grep dirscan_dir "${config_dir}/sabnzbd.ini" | awk '{print $3}')"
   sabnzbd_incoming_dir="$(grep download_dir "${config_dir}/sabnzbd.ini" | awk '{print $3}')"
   sabnzbd_complete_dir="$(grep complete_dir "${config_dir}/sabnzbd.ini" | awk '{print $3}')"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Correct owner and group of syncronised files, if required"
   find "${config_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${config_dir}" ! -group "${group}" -exec chgrp "${group}" {} \;
   find "${app_base_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${app_base_dir}" ! -group "${group}" -exec chgrp "${group}" {} \;
   find "${nzb2media_base_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${nzb2media_base_dir}" ! -group "${group}" -exec chgrp "${group}" {} \;
   if [ "${sabnzbd_watch_dir}" ] && [ -d "${sabnzbd_watch_dir}" ]; then
      find "${sabnzbd_watch_dir}" -type d ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   fi
   if [ "${sabnzbd_incoming_dir}" ] && [ -d "${sabnzbd_incoming_dir}" ]; then
      find "${sabnzbd_incoming_dir}" -type d ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   fi
   if [ "${sabnzbd_complete_dir}" ] && [ -d "${sabnzbd_complete_dir}" ]; then
      find "${sabnzbd_complete_dir}"  -type d ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   fi
}

LaunchSABnzbd(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Starting SABnzbd as ${stack_user}"
   su "${stack_user}" -c "python ${app_base_dir}/SABnzbd.py --config-file ${config_dir}/sabnzbd.ini --browser 0"
}

##### Script #####
Initialise
CreateGroup
CreateUser
if [ ! -d "${config_dir}/admin" ]; then FirstRun; fi
EnableSSL
Configure
InstallnzbToMedia
SetOwnerAndGroup
LaunchSABnzbd