FROM alpine:latest

# mountable volumes
# where to find htpasswd
VOLUME "/config"
# where to store files
VOLUME "/srv/ftp"

# install the required packages
RUN \
	apk add --no-cache \
		vsftpd \
		curl build-base linux-pam-dev tar
# build libpam-pwdfile
RUN \
	cd /tmp \
	&& curl -sSL http://github.com/tiwe-de/libpam-pwdfile/archive/v1.0.tar.gz | tar xz  \
	&& cd libpam-pwdfile-1.0 \
	&& make install \
	&& cd / \
	&& rm -r /tmp/libpam-pwdfile-1.0
# remove unnecessary dependencies
RUN \
	apk del --no-cache \
		curl build-base linux-pam-dev tar
# prepare user for running vsftpd
RUN \
	adduser -S -D -h / -s /bin/false ftpsecure

# copy configuration and run script
COPY ./pam-vsftpd /etc/pam.d/vsftpd
COPY ./vsftpd.conf /etc/vsftpd.conf
COPY ./vsftpd.sh /root/vsftpd.sh

EXPOSE 21
EXPOSE 50000-50100

CMD /root/vsftpd.sh

