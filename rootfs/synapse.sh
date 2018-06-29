#!/bin/sh

CONF_PATH=/data/conf

mkdir -p "${CONF_PATH}"
chown synapse:synapse /data
chown synapse:synapse "${CONF_PATH}"

if [ ! -e ${CONF_PATH}/signing_key.dh ]; then
	gosu synapse /usr/bin/python2 -m synapse.app.homeserver --config-path "${CONF_PATH}/default.yaml" \
	--generate-config --report-stats no --server-name localhost > /dev/null

	mv "${CONF_PATH}/localhost.tls.crt" "${CONF_PATH}/federation.crt"
	mv "${CONF_PATH}/localhost.tls.key" "${CONF_PATH}/federation.key"
	mv "${CONF_PATH}/localhost.tls.dh" "${CONF_PATH}/federation.dh"
	mv "${CONF_PATH}/localhost.signing.key" "${CONF_PATH}/signing.key"

	cat "${CONF_PATH}/default.yaml" | grep macaroon_secret_key | cut -d ':' -f 2 | tr -d ' "\n' > "${CONF_PATH}/macaroon_secret_key"
	cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1 > "${CONF_PATH}/password.pepper"

	rm -f "${CONF_PATH}/default.yaml"
fi

chown synapse:synapse -R  "${CONF_PATH}"

export MACAROON_SECRET_KEY="$(cat ${CONF_PATH}/macaroon_secret_key | tr -d ' \n')"
export PASSWORD_CONFIG_PEPPER="$(cat ${CONF_PATH}/password.pepper | tr -d ' \n')"


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

gosu synapse consul-template -once -consul-addr='' -vault-addr='' -consul-retry="false" -template "/conf-tmpl/log.yaml.tmpl:${CONF_PATH}/log.yaml"
gosu synapse consul-template -once -consul-addr='' -vault-addr='' -consul-retry="false" -template "/conf-tmpl/synapse.yaml.tmpl:${CONF_PATH}/synapse.yaml"

MEDIA_STORE_PATH=${MEDIA_STORE_PATH:-$(cat ${CONF_PATH}/synapse.yaml | grep media_store_path | cut -d ':' -f 2 | tr -d ' ')}
UPLOADS_PATH=${UPLOADS_PATH:-$(cat ${CONF_PATH}/synapse.yaml | grep uploads_path | cut -d ':' -f 2 | tr -d ' ')}

mkdir -p "${MEDIA_STORE_PATH}"
mkdir -p "${UPLOADS_PATH}"

chown synapse:synapse "${MEDIA_STORE_PATH}"
chown synapse:synapse "${UPLOADS_PATH}"


gosu synapse /usr/bin/python2 -m synapse.app.homeserver --config-path "${CONF_PATH}/synapse.yaml"
