#!/bin/sh

CERT_PATH=/var/www/mendersoftware/cert/cert.crt
KEY_PATH=/var/www/mendersoftware/cert/private.key

waserr=0
for f in $CERT_PATH $KEY_PATH; do
    if ! test -e $f; then
        echo "required file $f not found in container"
        waserr=1
    fi
done

if [ "$waserr" = "1" ]; then
   echo "certificate or key not found, exiting"
   exit 1
fi

if [ -n "$ALLOWED_HOSTS" ]; then
    sed -i -e "s/[@]ALLOWED_HOSTS[@]/$ALLOWED_HOSTS/" /etc/nginx/nginx.conf
else
   echo "ALLOWED_HOSTS undefined, exiting"
   exit 1
fi

exec nginx -g "daemon off;" $*
