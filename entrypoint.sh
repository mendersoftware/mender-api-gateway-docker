#!/bin/sh

SSL=${SSL:-true}

SERVER_BLOCKS_FILENAME="non-ssl"

if [ "$SSL" = "true" ] || [ "$SSL" = "TRUE" ] || [ "$SSL" = "1" ]; then
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

   SERVER_BLOCKS_FILENAME="ssl"
fi

sed -i -e "s/[@]INCLUDE_SERVER_BLOCKS[@]/include \/usr\/local\/openresty\/nginx\/conf\/$SERVER_BLOCKS_FILENAME.nginx.conf;/" \
   /usr/local/openresty/nginx/conf/nginx.conf

if [ -n "$ALLOWED_HOSTS" ]; then
    sed -i -e "s/[@]ALLOWED_HOSTS[@]/$ALLOWED_HOSTS/" /usr/local/openresty/nginx/conf/ssl.nginx.conf
    sed -i -e "s/[@]ALLOWED_HOSTS[@]/$ALLOWED_HOSTS/" /usr/local/openresty/nginx/conf/non-ssl.nginx.conf

    # generate ORIGIN whitelist
    if [ "$ALLOWED_HOSTS" != "_" ]; then
        hosts=$(echo $ALLOWED_HOSTS | sed 's/ \{1,\}/|/g' | sed 's/[.]\{1,\}/\\\\\\./g')
    else
        hosts=".*"
    fi
    sed -i -e "s/[@]ALLOWED_ORIGIN_HOSTS[@]/$hosts/" /usr/local/openresty/nginx/conf/common.nginx.conf
else
   echo "ALLOWED_HOSTS undefined, exiting"
   exit 1
fi

# Disabled by default
sed -i -e "s/[@]CACHE_UI_BROWSER_PERIOD[@]/${CACHE_UI_BROWSER_PERIOD:=off}/" \
   /usr/local/openresty/nginx/conf/common.nginx.conf

# Disabled by default
sed -i -e "s/[@]CACHE_UI_SUCCESS_PERIOD[@]/${CACHE_UI_SUCCESS_PERIOD:=0s}/" \
   /usr/local/openresty/nginx/conf/common.nginx.conf

# Disabled by default
sed -i -e "s/[@]CACHE_UI_FAILURE_PERIOD[@]/${CACHE_UI_FAILURE_PERIOD:=0s}/" \
   /usr/local/openresty/nginx/conf/common.nginx.conf

if [ -n "$HAVE_MULTITENANT" ]; then
    ln -sf /usr/local/openresty/nginx/conf/tenantadm.nginx.conf \
       /usr/local/openresty/nginx/conf/optional/endpoints/tenantadm.nginx.conf
fi

if [ -n "$HAVE_AUDITLOGS" ]; then
    ln -sf /usr/local/openresty/nginx/conf/auditlogs.nginx.conf \
       /usr/local/openresty/nginx/conf/optional/endpoints/auditlogs.nginx.conf
fi

if [ -n "$HAVE_DEVICECONNECT" ]; then
    ln -sf /usr/local/openresty/nginx/conf/deviceconnect.nginx.conf \
       /usr/local/openresty/nginx/conf/optional/endpoints/deviceconnect.nginx.conf
fi

if [ -n "$HAVE_DEVICECONFIG" ]; then
    ln -sf /usr/local/openresty/nginx/conf/deviceconfig.nginx.conf \
       /usr/local/openresty/nginx/conf/optional/endpoints/deviceconfig.nginx.conf
fi

# Rate limits - disabled by default
if [ -n "$RATE_LIMIT_GLOBAL_RATE" ] && [ $RATE_LIMIT_GLOBAL_RATE -gt 0 ]; then
    sed -i -e "s/[@]RATE_LIMIT_GLOBAL_RATE[@]/${RATE_LIMIT_GLOBAL_RATE}r\/s/" /usr/local/openresty/nginx/conf/nginx.conf

    if [ -n "$RATE_LIMIT_GLOBAL_BURST" ] && [ $RATE_LIMIT_GLOBAL_BURST -gt 0 ]; then
        sed -i -e "s/[@]RATE_LIMIT_GLOBAL_BURST[@]/burst=$RATE_LIMIT_GLOBAL_BURST/" /usr/local/openresty/nginx/conf/nginx.conf
    else
        sed -i -e "s/[@]RATE_LIMIT_GLOBAL_BURST[@] //" /usr/local/openresty/nginx/conf/nginx.conf
    fi
else
    sed -i -e "/[@]RATE_LIMIT_GLOBAL_RATE[@]/d" /usr/local/openresty/nginx/conf/nginx.conf
    sed -i -e "/[@]RATE_LIMIT_GLOBAL_BURST[@]/d" /usr/local/openresty/nginx/conf/nginx.conf
    sed -i -e "/limit_req_status/d" /usr/local/openresty/nginx/conf/nginx.conf
fi

# Enabling access logs json format - disabled by default
if [ -n "$IS_LOGS_FORMAT_JSON" ] && [ "$IS_LOGS_FORMAT_JSON" = "true" ]; then
    sed -i -e "s/[@]LOGS_FORMAT[@]/access_log_json/g" /usr/local/openresty/nginx/conf/nginx.conf
else
    sed -i -e "s/[@]LOGS_FORMAT[@]/main/g" /usr/local/openresty/nginx/conf/nginx.conf
fi

# HTTP Strict Transport Security max-age - 2yrs by default
sed -i -e "s/[@]HSTS_MAX_AGE[@]/${HSTS_MAX_AGE:=63072000}/" /usr/local/openresty/nginx/conf/ssl.nginx.conf

DNS_NAMES=${DNS_NAMES:-mender-useradm mender-inventory mender-deployments \
                                      mender-device-auth mender-device-adm \
                                      mender-gui}

echo "setting up automatic reload on host IP address changes for DNS names: $(echo $DNS_NAMES | tr -s " ")"

./reload-when-hosts-changed $DNS_NAMES &

exec /usr/local/openresty/bin/openresty -g "daemon off;" $*
