ARG UBUNTU_VERSION="bionic"
FROM ubuntu:"${UBUNTU_VERSION}"

# default config
ARG DEBIAN_FRONTEND=noninteractive
# config deps
ARG ELASTIC_VERSION="6.7.1"
ARG NODE_VERSION="11"

# config communityserver release
ARG RELEASE_DATE="2018-10-26"
ARG RELEASE_DATE_SIGN=""
ARG COM_SRV_VERSION="9.6.4"
ARG COM_SRV_BUILD="736_all"
ARG SOURCE_REPO_URL="https://downloads.sourceforge.net/project/teamlab/ONLYOFFICE_CommunityServer/v9.6/binaries/onlyoffice-communityserver_${COM_SRV_VERSION}.${COM_SRV_BUILD}.deb"

LABEL onlyoffice.community.release-date="${RELEASE_DATE}" \
      onlyoffice.community.version="${VERSION}" \
      onlyoffice.community.release-date.sign="${RELEASE_DATE_SIGN}" \
      maintainer="mko-x <code@m-ko.de>"

ENV LANGUAGE="en_US:en"
ENV	LC_ALL="en_US.UTF-8"
ENV	LANG="en_US.UTF-8"
ENV UBUNTU_VERSION="${UBUNTU_VERSION:-bionic}"
    
RUN echo "Build with ubuntu version: ${UBUNTU_VERSION}" && \
    apt-get -y update && \
    apt-get -yq install gnupg2 nano && \
    apt-get install -yq sudo locales && \
    addgroup --system --gid 107 onlyoffice && \
    adduser -uid 104 --quiet --home /var/www/onlyoffice --system --gid 107 onlyoffice && \
    addgroup --system --gid 104 elasticsearch && \
    adduser -uid 103 --quiet --home /nonexistent --system --gid 104 elasticsearch && \
    echo "deb http://download.mono-project.com/repo/ubuntu stable-${UBUNTU_VERSION} main" | tee /etc/apt/sources.list.d/mono-official.list && \
    echo "deb http://download.onlyoffice.com/repo/mono/ubuntu ${UBUNTU_VERSION} main" | tee /etc/apt/sources.list.d/mono-onlyoffice.list && \    
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys CB2DE8E5 && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    locale-gen en_US.UTF-8 && \
    apt-get -y update && \
    apt-get install -yq software-properties-common wget curl cron rsyslog


RUN wget http://nginx.org/keys/nginx_signing.key && \
    apt-key add nginx_signing.key && \
    echo "deb http://nginx.org/packages/mainline/ubuntu/ ${UBUNTU_VERSION} nginx" >> /etc/apt/sources.list.d/nginx.list && \
    echo "deb-src http://nginx.org/packages/mainline/ubuntu/ ${UBUNTU_VERSION} nginx" >> /etc/apt/sources.list.d/nginx.list && \
    apt-get install -yq openjdk-8-jre-headless && \
    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
    apt-get install -yq apt-transport-https && \
    echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-6.x.list && \
    apt-get update && \
    apt-get install -yq elasticsearch=${ELASTIC_VERSION} && \
    add-apt-repository -y ppa:certbot/certbot && \
    add-apt-repository -y ppa:chris-lea/redis-server && \
    add-apt-repository -y ppa:jonathonf/ffmpeg-4 && \
    curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash - && \
    sudo apt-get install -y nodejs

RUN apt-get -y update && \
    apt-get install -yq nginx mono-complete ca-certificates-mono && \
    echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d && \
    apt-get install -yq dumb-init python-certbot-nginx htop nano dnsutils redis-server python3-pip multiarch-support iproute2 ffmpeg && \
    apt-get install -yq mono-webserver-hyperfastcgi   
    


RUN wget "${SOURCE_REPO_URL}" -o "onlyoffice-communityserver_${VERSION}.${BUILD}}.deb" && \
    apt install -fyq "onlyoffice-communityserver_${VERSION}.${BUILD}}.deb" && \
    rm -rf /var/lib/apt/lists/*

ADD config /app/onlyoffice/config/
ADD assets /app/onlyoffice/assets/
ADD run-community-server.sh /app/onlyoffice/run-community-server.sh
RUN chmod -R 755 /app/onlyoffice/*.sh

VOLUME ["/var/log/onlyoffice", "/var/www/onlyoffice/Data", "/var/lib/mysql"]

EXPOSE 80 443 5222 3306 9865 9888 9866 9871 9882 5280

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["/app/onlyoffice/run-community-server.sh"];