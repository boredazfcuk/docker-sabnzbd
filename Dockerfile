FROM alpine:latest
MAINTAINER boredazfcuk
ARG build_dependencies="gcc python-dev musl-dev libffi-dev openssl-dev automake autoconf g++ make"
ARG app_dependencies="git python python3 py-pip tzdata libgomp unrar unzip p7zip ffmpeg openssl ca-certificates"
ARG python_dependencies="cheetah3 cryptography sabyenc"
ARG app_repo="sabnzbd/sabnzbd"
ARG parchive_repo="Parchive/par2cmdline"
ENV config_dir="/config" \
   app_base_dir="/SABnzbd"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED *****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Create directories" && \
   mkdir -p "${app_base_dir}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install build dependencies" && \
   apk add --no-cache --no-progress --virtual=build-deps ${build_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install application dependencies" && \
   apk add --no-cache --no-progress ${app_dependencies} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install ${app_repo}" && \
   git clone -b master "https://github.com/${app_repo}.git" "${app_base_dir}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install ${app_repo} python dependencies" && \
   cd "${app_base_dir}" && \
   pip install --no-cache-dir --upgrade pip && \
   pip install --no-cache-dir ${python_dependencies} && \
   "${app_base_dir}/tools/make_mo.py" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install ${parchive_repo}" && \
   temp_dir="$(mktemp -d)" && \
   git clone -b master "https://github.com/${parchive_repo}.git" "${temp_dir}" && \
   cd "${temp_dir}" && \
   aclocal && \
   automake --add-missing && \
   autoconf && \
   ./configure && \
   make && \
   make check && \
   make install && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Clean up" && \
   apk del --no-progress --purge build-deps && \
   rm -rv "/root/.cache/pip" "${temp_dir}"

COPY start-sabnzbd.sh /usr/local/bin/start-sabnzbd.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh
COPY sabnzbd.ini /config/sabnzbd.ini

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | Set permissions on scripts" && \
   chmod +x /usr/local/bin/start-sabnzbd.sh /usr/local/bin/healthcheck.sh && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD COMPLETE *****"

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
   CMD /usr/local/bin/healthcheck.sh

VOLUME "${config_dir}"
WORKDIR "${app_base_dir}"

CMD /usr/local/bin/start-sabnzbd.sh