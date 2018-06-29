FROM johannweging/base-alpine:latest

ARG SYNAPSE_VERSION

ENV SYNAPSE_VERSON=${SYNAPSE_VERSION} CONSUL_TEMPLATE_VERSION=0.19.5

RUN set -x \
&& curl https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.tgz > /tmp/consul-template.tgz \
&& cd /tmp \
&& tar -xf consul-template.tgz \
&& mv consul-template /usr/bin \
&& cd / \
&& rm -rf /tmp/*

RUN set -x \
&& apk add --update --no-cache python2 py2-pip libffi openssl mailcap py2-psycopg2 jpeg

RUN set -x \
&& apk add --update --no-cache --virtual .deps git gcc make linux-headers musl-dev python2-dev py2-pip libffi-dev openssl-dev jpeg-dev \
&& git clone --branch v${SYNAPSE_VERSION} --depth 1 https://github.com/matrix-org/synapse.git /tmp/synapse \
&& cd /tmp/synapse \
&& pip install -U . \
&& cd / \
&& pip install matrix-angular-sdk \
&& rm -rf /tmp/* /root/.cache \
&& apk del .deps

RUN set -x \
&& createuser synapse

ADD rootfs /

RUN set -x \
&& chmod +x /synapse.sh

VOLUME ["/data"]
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/synapse.sh"]
