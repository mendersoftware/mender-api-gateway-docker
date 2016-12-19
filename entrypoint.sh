#!/bin/sh

CERT_PATH=/var/www/mendersoftware/cert/cert.pem
KEY_PATH=/var/www/mendersoftware/cert/key.pem

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

exec /usr/local/openresty/bin/openresty -g "daemon off;" $*
