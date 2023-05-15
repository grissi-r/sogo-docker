FROM debian:bullseye-slim

ENV \
    LC_ALL=C \
    LANG=C \
    DEBIAN_FRONTEND=noninteractive

EXPOSE 80 

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    default-mysql-client \
    apt-transport-https \
    ca-certificates \
    gnupg \
    dirmngr \
    memcached \
    apt-utils

RUN mkdir /usr/share/doc/sogo \
        && touch /usr/share/doc/sogo/empty.sh \
        && wget -O- "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xb022c48d3d6373d7fc256a8ccb2d3a2aa0030e2c" | gpg --dearmor | apt-key add - \
        && wget -O- "https://keys.openpgp.org/vks/v1/by-fingerprint/74FFC6D72B925A34B5D356BDF8A27B36A6E2EAE9" | gpg --dearmor | apt-key add - \
        && echo "deb http://packages.sogo.nu/nightly/5/debian/ bullseye bullseye" > /etc/apt/sources.list.d/sogo.list \
        && apt-get update && apt-get install -y  \
		sogo \
		sogo-activesync \
    && apt-get autoremove --purge \
    && wget -qO- $(wget -nv -qO- https://api.github.com/repos/jwilder/dockerize/releases/latest \
                | grep -E 'browser_.*dockerize-linux-amd64' | cut -d\" -f4) | tar xzv -C /usr/local/bin/ \
	&& rm -rf /var/lib/apt/lists/* /var/log/* /tmp/* /var/tmp/* \
	&& chmod o+x -R /usr/local/bin/


COPY ["script", "/usr/local/bin/"]

CMD ["/usr/local/bin/start.sh"]
