FROM alpine:latest
MAINTAINER boredazfcuk
ARG BUILDDEPENDENCIES="gcc python-dev musl-dev libffi-dev openssl-dev automake autoconf g++ make"
ARG APPDEPENDENCIES="git python python3 py-pip tzdata libgomp unrar unzip p7zip ffmpeg openssl ca-certificates"
ARG SABPYTHONDEPENDENCIES="cheetah3 cryptography sabyenc"
ARG SABREPO="sabnzbd/sabnzbd"
ARG PARREPO="Parchive/par2cmdline"
ENV CONFIGDIR="/config" \
   SABBASE="/SABnzbd"

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED *****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Create directories" && \
   mkdir -p "${SABBASE}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install build dependencies" && \
   apk add --no-cache --no-progress --virtual=build-deps ${BUILDDEPENDENCIES} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install application dependencies" && \
   apk add --no-cache --no-progress ${APPDEPENDENCIES} && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install ${SABREPO}" && \
   git clone -b master "https://github.com/${SABREPO}.git" "${SABBASE}" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install ${SABREPO} python dependencies" && \
   cd "${SABBASE}" && \
   pip install --no-cache-dir --upgrade pip && \
   pip install --no-cache-dir ${SABPYTHONDEPENDENCIES} && \
   "${SABBASE}/tools/make_mo.py" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install ${PARREPO}" && \
   TEMP="$(mktemp -d)" && \
   git clone -b master "https://github.com/${PARREPO}.git" "${TEMP}" && \
   cd "${TEMP}" && \
   aclocal && \
   automake --add-missing && \
   autoconf && \
   ./configure && \
   make && \
   make check && \
   make install && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Clean up" && \
   apk del --no-progress --purge build-deps && \
   rm -rv "/root/.cache/pip" "${TEMP}"

COPY start-sabnzbd.sh /usr/local/bin/start-sabnzbd.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh
COPY sabnzbd.ini /config/sabnzbd.ini

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | Set permissions on scripts" && \
   chmod +x /usr/local/bin/start-sabnzbd.sh /usr/local/bin/healthcheck.sh && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD COMPLETE *****"

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
   CMD /usr/local/bin/healthcheck.sh

VOLUME "${CONFIGDIR}"
WORKDIR "${SABBASE}"

CMD /usr/local/bin/start-sabnzbd.sh