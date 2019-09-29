FROM alpine:latest
MAINTAINER boredazfcuk
ENV SABBASE="/SABnzbd" \
   N2MBASE="/nzbToMedia" \
   BUILDDEPENDENCIES="gcc python-dev musl-dev libffi-dev openssl-dev automake autoconf g++ make" \
	APPDEPENDENCIES="git python python3 py-pip tzdata unrar unzip p7zip ffmpeg" \
   SABPYTHONDEPENDENCIES="cheetah3 cryptography sabyenc" \
	CONFIGDIR="/config" \
	SABREPO="sabnzbd/sabnzbd" \
	PARREPO="Parchive/par2cmdline" \
   N2MREPO="clinton-hall/nzbToMedia"

COPY start-sabnzbd.sh /usr/local/bin/start-sabnzbd.sh

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED *****" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Create directories" && \
   mkdir -p "${SABBASE}" "${N2MBASE}" && \
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
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Install ${N2MREPO}" && \
   cd "${N2MBASE}" && \
   git clone -b master "https://github.com/${N2MREPO}.git" "${N2MBASE}" && \
   mkdir /shared && \
   touch "/shared/autoProcessMedia.cfg" && \
   ln -s "/shared/autoProcessMedia.cfg" "${N2MBASE}/autoProcessMedia.cfg" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | Clean up" && \
   chmod +x /usr/local/bin/start-sabnzbd.sh && \
   apk del --no-progress --purge build-deps && \
   rm -rv "/shared" "/root/.cache/pip" && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD COMPLETE *****"

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
   CMD wget --quiet --tries=1 --spider "http://${HOSTNAME}:8080/sabnzbd" || exit 1

VOLUME "${CONFIGDIR}"

CMD /usr/local/bin/start-sabnzbd.sh