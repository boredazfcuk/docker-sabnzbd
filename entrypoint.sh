#!/bin/ash

##### Functions #####
Initialise(){
   lan_ip="$(hostname -i)"
   nzb2media_base_dir="/nzbToMedia"
   nzb2media_repo="clinton-hall/nzbToMedia"
   echo
   echo "$(date '+%c') INFO:    ***** Configuring SABnzbd container launch environment *****"
   echo "$(date '+%c') INFO:    $(cat /etc/*-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//g' | sed 's/"//g')"
   echo "$(date '+%c') INFO:    Local user: ${stack_user:=stackman}:${user_id:=1000}"
   echo "$(date '+%c') INFO:    Password: ${stack_password:=Skibidibbydibyodadubdub}"
   echo "$(date '+%c') INFO:    Local group: ${sabnzbd_group:=sabnzbd}:${sabnzbd_group_id:=1000}"
   echo "$(date '+%c') INFO:    SABnzbd application directory: ${app_base_dir}"
   echo "$(date '+%c') INFO:    Listening IP Address: ${lan_ip}"
   echo "$(date '+%c') INFO:    Movie complete directory: ${movie_complete_dir:=/storage/downloads/complete/movie/}"
   echo "$(date '+%c') INFO:    Music complete directory: ${music_complete_dir:=/storage/downloads/complete/music/}"
   echo "$(date '+%c') INFO:    Other downloads complete directory: ${other_complete_dir:=/storage/downloads/complete/other/}"
   echo "$(date '+%c') INFO:    TV complete directory: ${tv_complete_dir:=/storage/downloads/complete/tv/}"
   echo "$(date '+%c') INFO:    Watch directory: ${sabnzbd_watch_dir=/storage/downloads/watch/sabnzbd/}"
   echo "$(date '+%c') INFO:    NZB file backup directory: ${sabnzbd_file_backup_dir:=/storage/downloads/backup/sabnzbd/}"
}

CreateGroup(){
   if [ -z "$(getent group "${sabnzbd_group}" | cut -d: -f3)" ]; then
      echo "$(date '+%c') INFO:    Group ID available, creating group"
      addgroup -g "${sabnzbd_group_id}" "${sabnzbd_group}"
   elif [ ! "$(getent group "${sabnzbd_group}" | cut -d: -f3)" = "${sabnzbd_group_id}" ]; then
      echo "$(date '+%c') ERROR:   Group group_id mismatch - exiting"
      exit 1
   fi
}

CreateUser(){
   if [ -z "$(getent passwd "${stack_user}" | cut -d: -f3)" ]; then
      echo "$(date '+%c') INFO:    User ID available, creating user"
      adduser -s /bin/ash -D -G "${sabnzbd_group}" -u "${user_id}" "${stack_user}"
   elif [ ! "$(getent passwd "${stack_user}" | cut -d: -f3)" = "${user_id}" ]; then
      echo "$(date '+%c') ERROR:   User ID already in use - exiting"
      exit 1
   fi
}

FirstRun(){
   echo "$(date '+%c') INFO:    First run detected - create default config"
   find "${config_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${config_dir}" ! -group "${sabnzbd_group}" -exec chgrp "${sabnzbd_group}" {} \;
   su -p "${stack_user}" -c "python ${app_base_dir}/SABnzbd.py --config-file ${config_dir}/sabnzbd.ini --daemon --pidfile /tmp/sabnzbd.pid --browser 0"
   sleep 15
   echo "$(date '+%c') INFO:    ***** Reload SABnzbd launch environment *****"
   pkill python
   sleep 5
   echo "$(date '+%c') INFO:    Customise SABnzbd default config"
   sed -i \
      -e "/^\[misc\]/,/^\[.*\]/ s%^empty_postproc =.*%empty_postproc = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^safe_postproc =.*%safe_postproc = 0%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^fail_hopeless_jobs = .*%fail_hopeless_jobs = 0%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^fast_fail =.*%fast_fail = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^script_can_fail =.*%script_can_fail = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^notified_new_skin =.*%notified_new_skin = 2%" \
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
      -e "/^\[misc\]/,/^\[.*\]/ s%^dirscan_speed =.*%dirscan_speed = 60%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^pre_check =.*%pre_check = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^web_dir =.*%web_dir = Plush%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^download_free =.*%download_free = 80G%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^par_option =.*%par_option = -N -t%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^pause_on_pwrar =.*%pause_on_pwrar = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^replace_spaces =.*%replace_spaces = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^replace_dots =.*%replace_dots = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^sanitize_safe =.*%sanitize_safe = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^direct_unpack =.*%direct_unpack = 0%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^direct_unpack_tested =.*%direct_unpack_tested = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^warn_dupl_jobs =.*%warn_dupl_jobs = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^enable_par_cleanup =.*%enable_par_cleanup = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^flat_unpack =.*%flat_unpack = 1%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^history_retention =.*%history_retention = 7d%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^ipv6_servers =.*%ipv6_servers = 0%" \
      -e "/^\[misc\]/,/^\[.*\]/ s%^ignore_empty_files =.*%ignore_empty_files = 1%" \
      "${config_dir}/sabnzbd.ini"
   sleep 1
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
   if [ "${sabnzbd_enabled}" ]; then
      sed -i \
         -e "/^\[misc\]/,/^\[.*\]/ s%^url_base =.*%url_base = /sabnzbd%" \
         "${config_dir}/sabnzbd.ini"
   else
      sed -i \
         -e "/^\[misc\]/,/^\[.*\]/ s%^url_base =.*%url_base = /%" \
         "${config_dir}/sabnzbd.ini"

   fi
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
      echo "$(date '+%c') INFO:    Access domain: ${media_access_domain}"
      host_verification_access_list="$(sed -nr '/\[misc\]/,/\[/{/^host_whitelist =/p}' "${config_dir}/sabnzbd.ini")"
      if [ "$(grep -c "${media_access_domain}" "${config_dir}/sabnzbd.ini")" = 0 ]; then
         sed -i \
            -e "s%^${host_verification_access_list}$%${host_verification_access_list} ${media_access_domain},%" \
            "${config_dir}/sabnzbd.ini"
      fi
   else
      echo "$(date '+%c') WARNING: Access domain not set, SABnzbd will only be accessible by IP address"
   fi
}

InstallnzbToMedia(){
   if [ ! -f "${nzb2media_base_dir}/nzbToMedia.py" ]; then
      if [ -d "${nzb2media_base_dir}" ]; then
         echo "$(date '+%c') INFO:    Cleaning up previously failed installation"
         rm -r "${nzb2media_base_dir}"
      fi
      mkdir -p "${nzb2media_base_dir}"
      chown "${stack_user}":"${sabnzbd_group}" "${nzb2media_base_dir}"
      echo "$(date '+%c') INFO:    ${nzb2media_repo} not detected, installing..."
      cd "${nzb2media_base_dir}"
      su "${stack_user}" -c "git clone --branch master https://github.com/${nzb2media_repo}.git ${nzb2media_base_dir}"
   fi
   if [ ! -f "${nzb2media_base_dir}/autoProcessMedia.cfg" ]; then
         cp "${nzb2media_base_dir}/autoProcessMedia.cfg.spec" "${nzb2media_base_dir}/autoProcessMedia.cfg"
   fi
}

ConfigurenzbToMedia(){
   echo "$(date '+%c') INFO:    Configure nzbToMedia general settings"
   sed -i \
      -e "/^\[General\]/,/^\[.*\]/ s%auto_update =.*%auto_update = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%git_path =.*%git_path = /usr/bin/git%" \
      -e "/^\[General\]/,/^\[.*\]/ s%git_branch =.*%git_branch = master%" \
      -e "/^\[General\]/,/^\[.*\]/ s%ffmpeg_path.*%ffmpeg_path = /usr/local/bin/ffmpeg%" \
      -e "/^\[General\]/,/^\[.*\]/ s%safe_mode =.*%safe_mode = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%no_extract_failed =.*%no_extract_failed = 1%" \
      -e "/^\[General\]/,/^\[.*\]/ s%git_branch =.*%git_branch = master%" \
      "${nzb2media_base_dir}/autoProcessMedia.cfg"
}

N2MSABnzbd(){
   echo "$(date '+%c') INFO:    Configure nzbToMedia SABnzbd settings"
   sed -i \
      -e "/^\[Nzb\]/,/^\[.*\]/ s%clientAgent =.*%clientAgent = sabnzbd%" \
      -e "/^\[Nzb\]/,/^\[.*\]/ s%sabnzbd_host =.*%sabnzbd_host = http://sabnzbd%" \
      -e "/^\[Nzb\]/,/^\[.*\]/ s%sabnzbd_port.*%sabnzbd_port = 9090%" \
      -e "/^\[Nzb\]/,/^\[.*\]/ s%sabnzbd_apikey =.*%sabnzbd_apikey = ${global_api_key}%" \
      -e "/^\[Nzb\]/,/^\[.*\]/ s%default_downloadDirectory =.*%default_downloadDirectory = ${other_complete_dir}%" \
      "${nzb2media_base_dir}/autoProcessMedia.cfg"
}

N2MCouchPotato(){
   if [ "${couchpotato_enabled}" ]; then
      echo "$(date '+%c') INFO:    Configure nzbToMedia CouchPotato settings"
      sed -i \
         -e "/^\[CouchPotato\]/,/^\[.*\]/ s%enabled = .*%enabled = 1%" \
         -e "/^\[CouchPotato\]/,/###### ADVANCED USE/ s%apikey =.*%apikey = ${global_api_key}%" \
         -e "/^\[CouchPotato\]/,/^\[.*\]/ s%host =.*%host = couchpotato%" \
         -e "/^\[CouchPotato\]/,/^\[.*\]/ s%port =.*%port = 5050%" \
         -e "/^\[CouchPotato\]/,/^\[.*\]/ s%ssl =.*%ssl = 0%" \
         -e "/^\[CouchPotato\]/,/^\[.*\]/ s%web_root =.*%web_root = /couchpotato%" \
         -e "/^\[CouchPotato\]/,/^\[.*\]/ s%minSize =.*%minSize = 3000%" \
         -e "/^\[CouchPotato\]/,/^\[.*\]/ s%delete_failed =.*%delete_failed = 1%" \
         -e "/^\[CouchPotato\]/,/^\[.*\]/ s%delete_ignored =.*%delete_ignored = 1%" \
         -e "/^\[CouchPotato\]/,/^\[.*\]/ s%watch_dir =.*%watch_dir = ${movie_complete_dir}%" \
         "${nzb2media_base_dir}/autoProcessMedia.cfg"
   fi
}

N2MSickGear(){
   if [ "${sickgear_enabled}" ]; then
      echo "$(date '+%c') INFO:    Configure nzbToMedia SickGear settings"
      sed -i \
         -e "/^\[SickBeard\]/,/^\[.*\]/ s%enabled = .*%enabled = 1%" \
         -e "/^\[SickBeard\]/,/^\[.*\]/ s%apikey =.*%apikey = ${global_api_key}%" \
         -e "/^\[SickBeard\]/,/^\[.*\]/ s%host =.*%host = sickgear%" \
         -e "/^\[SickBeard\]/,/^\[.*\]/ s%port =.*%port = 8081%" \
         -e "/^\[SickBeard\]/,/^\[.*\]/ s%ssl =.*%ssl = 0%" \
         -e "/^\[SickBeard\]/,/^\[.*\]/ s%fork =.*%fork = sickgear%" \
         -e "/^\[SickBeard\]/,/^\[.*\]/ s%web_root =.*%web_root = /sickgear%" \
         -e "/^\[SickBeard\]/,/^\[.*\]/ s%minSize =.*%minSize = 350%" \
         -e "/^\[SickBeard\]/,/^\[.*\]/ s%delete_failed =.*%delete_failed = 1%" \
         -e "/^\[SickBeard\]/,/^\[.*\]/ s%delete_ignored =.*%delete_ignored = 1%" \
         -e "/^\[SickBeard\]/,/^\[.*\]/ s%watch_dir =.*%watch_dir = ${tv_complete_dir}%" \
         "${nzb2media_base_dir}/autoProcessMedia.cfg"
   fi
}

N2MHeadphones(){
   if [ "${headphones_enabled}" ]; then
      echo "$(date '+%c') INFO:    Configure nzbToMedia Headphones settings"
      sed -i \
         -e "/^\[HeadPhones\]/,/^\[.*\]/ s%enabled = .*%enabled = 1%" \
         -e "/^\[HeadPhones\]/,/^\[.*\]/ s%apikey =.*%apikey = ${global_api_key}%" \
         -e "/^\[HeadPhones\]/,/^\[.*\]/ s%host =.*%host = headphones%" \
         -e "/^\[HeadPhones\]/,/^\[.*\]/ s%port =.*%port = 8181%" \
         -e "/^\[HeadPhones\]/,/^\[.*\]/ s%ssl =.*%ssl = 0%" \
         -e "/^\[HeadPhones\]/,/^\[.*\]/ s%web_root =.*%web_root = /headphones%" \
         -e "/^\[HeadPhones\]/,/^\[.*\]/ s%minSize =.*%minSize = 10%" \
         -e "/^\[HeadPhones\]/,/^\[.*\]/ s%delete_failed =.*%delete_failed = 1%" \
         -e "/^\[HeadPhones\]/,/^\[.*\]/ s%delete_ignored =.*%delete_ignored = 1%" \
         -e "/^\[HeadPhones\]/,/^\[.*\]/ s%watch_dir =.*%watch_dir = ${music_complete_dir}%" \
         "${nzb2media_base_dir}/autoProcessMedia.cfg"
   fi
}

SetOwnerAndGroup(){
   sabnzbd_watch_dir="$(grep dirscan_dir "${config_dir}/sabnzbd.ini" | awk '{print $3}')"
   sabnzbd_incoming_dir="$(grep download_dir "${config_dir}/sabnzbd.ini" | awk '{print $3}')"
   sabnzbd_complete_dir="$(grep complete_dir "${config_dir}/sabnzbd.ini" | awk '{print $3}')"
   echo "$(date '+%c') INFO:    Correct owner and group of syncronised files, if required"
   find "${config_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${config_dir}" ! -group "${sabnzbd_group}" -exec chgrp "${sabnzbd_group}" {} \;
   find "${app_base_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${app_base_dir}" ! -group "${sabnzbd_group}" -exec chgrp "${sabnzbd_group}" {} \;
   find "${nzb2media_base_dir}" ! -user "${stack_user}" -exec chown "${stack_user}" {} \;
   find "${nzb2media_base_dir}" ! -group "${sabnzbd_group}" -exec chgrp "${sabnzbd_group}" {} \;
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
   echo "$(date '+%c') INFO:    ***** Configuration of SABnzbd container launch environment complete *****"
   echo "$(date '+%c') INFO:    Starting SABnzbd as ${stack_user}"
   exec "$(which su)" "${stack_user}" -c "$(which python) ${app_base_dir}/SABnzbd.py --config-file ${config_dir}/sabnzbd.ini --browser 0"
}

##### Script #####
Initialise
CreateGroup
CreateUser
if [ ! -d "${config_dir}/admin" ]; then FirstRun; fi
Configure
InstallnzbToMedia
ConfigurenzbToMedia
N2MSABnzbd
N2MCouchPotato
N2MSickGear
N2MHeadphones
SetOwnerAndGroup
LaunchSABnzbd