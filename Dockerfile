FROM alpine:3.14.2
MAINTAINER boredazfcuk

# Version not used. Increment to force rebuild.
ARG sabnzbd_version="3.5"
ARG build_dependencies="gcc python3-dev musl-dev libffi-dev openssl-dev automake autoconf g++ make"
ARG app_dependencies="git ca-certificates python3 py3-pip tzdata libgomp unrar unzip p7zip ffmpeg openssl ca-certificates wget py3-cryptography py3-cffi"
ARG app_repo="sabnzbd/sabnzbd"
ARG parchive_repo="Parchive/par2cmdline"
ENV config_dir="/config" \
   app_base_dir="/SABnzbd"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED FOR SABNZBD *****" && \
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
   pip3 install --upgrade pip --no-cache-dir wheel requests && \
   pip3 install --no-cache-dir --requirement "${app_base_dir}/requirements.txt" && \
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
   ln -s /usr/bin/python3 /usr/bin/python && \
   apk del --no-progress --purge build-deps && \
   rm -rv "${temp_dir}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD COMPLETE *****"

COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chmod=0755 healthcheck.sh /usr/local/bin/healthcheck.sh
COPY sabnzbd.ini /config/sabnzbd.ini

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
   CMD /usr/local/bin/healthcheck.sh

VOLUME "${config_dir}"
WORKDIR "${app_base_dir}"

ENTRYPOINT /usr/local/bin/entrypoint.sh
