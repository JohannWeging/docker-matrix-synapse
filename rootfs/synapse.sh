#!/bin/sh

CONF_TEMPLATE_PATH="/conf/synapse.yaml.tmpl"
CONF_PATH="/conf/synapse.yaml"


if [ ! -e /conf/signing_key.dh ]; then
	gosu synapse /usr/bin/python2 -m synapse.app.homeserver --config-path /conf/default.yaml \
	--generate-config --report-stats no --server-name localhost > /dev/null

	mv /conf/localhost.tls.crt /conf/federation.crt
	mv /conf/localhost.tls.key /conf/federation.key
	mv /conf/localhost.tls.dh /conf/federation.dh
	mv /conf/localhost.signing.key /conf/signing.key

	cat /conf/default.yaml | grep macaroon_secret_key | cut -d ':' -f 2 | tr -d ' "\n' > /conf/macaroon_secret_key
	cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1 > /conf/password.pepper

	rm -f /conf/default.yaml
fi

mkdir -p /conf
chown -R synapse:synapse /conf

mkdir -p /data
chown -R synapse:synapse /data

export MACAROON_SECRET_KEY="$(cat /conf/macaroon_secret_key | tr -d ' \n')"
export PASSWORD_CONFIG_PEPPER="$(cat /conf/password.pepper | tr -d ' \n')"


if [ -z ${SERVER_NAME+x} ]; then
	echo "SERVER_NAME not set"
	exit 1
fi

if [ -z ${TLS_FINGERPRINTS+x} ]; then
	export TLS_FINGERPRINTS="$(openssl s_client -connect ${SERVER_NAME}:443 < /dev/null 2> /dev/null | openssl x509 -outform DER | openssl sha256 -binary | base64 | tr -d '=')"
	if [[ "$?" != "0" ]]; then
		echo "failed to grab ssl fingerprint / TLS_FINGERPRINTS not set"
		exit 1
	fi
fi

gosu synapse consul-template -once -consul-addr='' -vault-addr='' -consul-retry="false" -template "/conf/log.yaml.tmpl:/conf/log.yaml"
gosu synapse consul-template -once -consul-addr='' -vault-addr='' -consul-retry="false" -template "${CONF_TEMPLATE_PATH}:${CONF_PATH}"

MEDIA_STORE_PATH=${MEDIA_STORE_PATH:-$(cat /conf/synapse.yaml | grep media_store_path | cut -d ':' -f 2 | tr -d ' ')}
UPLOADS_PATH=${UPLOADS_PATH:-$(cat /conf/synapse.yaml | grep uploads_path | cut -d ':' -f 2 | tr -d ' ')}

mkdir -p "${MEDIA_STORE_PATH}"
mkdir -p "${UPLOADS_PATH}"

chown synapse:synapse "${MEDIA_STORE_PATH}"
chown synapse:synapse "${UPLOADS_PATH}"


gosu synapse /usr/bin/python2 -m synapse.app.homeserver --config-path /conf/synapse.yaml
