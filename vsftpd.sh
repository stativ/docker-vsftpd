#!/bin/sh
#
# Run vsftpd
#

# configuration
FTP_HOME=/srv/ftp

# check the required arguments
if [ -z $FTP_UID ] ; then
	echo "\$FTP_UID is not set"
	exit 1
fi
if [ -z $FTP_GID ] ; then
    echo "\$FTP_GID is not set"
    exit 1
fi

# prepare user and group with the specified FTP_UID/GID if they doesn't exists yet
getent group $FTP_GID
if [ $? -ne 0 ] ; then
	echo "creating group \"ftpvirtual\" with gid=$FTP_GID"
	addgroup -g $FTP_GID ftpvirtual
fi
FTP_GROUP=`getent group $FTP_GID | cut -d":" -f0`

getent passwd $FTP_UID
if [ $? -ne 0 ] ; then
	echo "creating user \"ftpvirtual\" with uid=$FTP_UID"
	adduser -D -G $FTP_GROUP -h /srv/ftp -s /bin/false -u $FTP_UID ftpvirtual
fi
FTP_USER=`getent passwd $FTP_UID | cut -d":" -f0`

# prepare home for all virtual users
while IFS= read -r LINE; do
	USERNAME=`echo $LINE | cut -d":" -f1`
	if [ ! -d "$FTP_HOME/$USERNAME" ] ; then
		echo "creating $FTP_HOME/$USERNAME"
		mkdir -p "$FTP_HOME/$USERNAME"
		chown $FTP_USER:$FTP_GROUP "$FTP_HOME/$USERNAME"
	fi
done < /config/htpasswd

# ensure proper permissions
chown $FTP_USER:$FTP_GROUP "$FTP_HOME"
chmod 550 "$FTP_HOME"

function vsftpd_stop() {
	PID=`cat /var/run/vsftpd.pid`
	echo "stopping vsftpd, pid=$PID"
	if [ $PID ] ; then
		kill -SIGTERM $PID
		wait "$PID"
	fi
	rm -f /var/run/vsftpd.pid
	echo "stopped"
}

# run vsftpd
# use the FTP_USER user for virtual users
echo "starting vsftpd"
trap vsftpd_stop SIGTERM
/usr/sbin/vsftpd -oguest_username=$FTP_USER $VSFTPD_ARGS &
PID="$!"
echo "$PID" > /var/run/vsftpd.pid
wait "$PID" && exit $?

