FROM openjdk:11-jdk-slim
# Build time variables
ARG MTA_USER_HOME=/home/mta
ARG MBT_VERSION=1.0.14
ARG NODE_VERSION=v12.16.1
ARG MAVEN_VERSION=3.6.3
ARG ARG_HTTP_PROXY
ARG ARG_HTTPS_PROXY
ARG ARG_NO_PROXY
# Provide environments
ENV PYTHON /usr/bin/python2.7
ENV M2_HOME=/opt/maven/apache-maven-${MAVEN_VERSION}
ENV NODE_HOME=/opt/nodejs
# Provide Runtime env
ENV PWD=/builds/gitlab/sap-ci-cd-poc/cloud-mta
# Provide proxy environments
ENV http_proxy=$ARG_HTTP_PROXY
ENV https_proxy=$ARG_HTTPS_PROXY
ENV no_proxy=$ARG_NO_PROXY
# Download required env tools
RUN apt-get update && \
    apt-get install --yes --no-install-recommends wget git unzip ssh zip vim build-essential python2.7 sudo jq && \
    # Change security level as the SAP npm repo doesn't support buster new security upgrade
    # the default configuration for OpenSSL in Buster explicitly requires using more secure ciphers and protocols,
    # and the server running at http://npm.sap.com/ is running software configured to only provide insecure, older ciphers.
    # This causes SSL connections using OpenSSL from a Buster based installation to fail
    # Should be remove once SAP npm repo will patch the security level
    # see - https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=912759
    sed -i -E 's/(CipherString\s*=\s*DEFAULT@SECLEVEL=)2/\11/' /etc/ssl/openssl.cnf
# Install yq processing tool
RUN curl -LJO https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 && \
    chmod a+rx yq_linux_amd64 && \
    mv yq_linux_amd64 /opt/yq
# Install node
RUN echo "[INFO] Install Node $NODE_VERSION." && \
    mkdir -p "${NODE_HOME}" && \
    wget -qO- "http://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.gz" | tar -xzf - -C "${NODE_HOME}" && \
    ln -s "${NODE_HOME}/node-${NODE_VERSION}-linux-x64/bin/node" /usr/local/bin/node && \
    ln -s "${NODE_HOME}/node-${NODE_VERSION}-linux-x64/bin/npm" /usr/local/bin/npm && \
    ln -s "${NODE_HOME}/node-${NODE_VERSION}-linux-x64/bin/npx" /usr/local/bin/ && \
    # Config NPM
    npm config set @sap:registry https://npm.sap.com --global
# Update Maven home and install Maven
RUN echo "[INFO] update Maven home and Install Maven $MAVEN_VERSION." && \
    M2_BASE="$(dirname ${M2_HOME})" && \
    mkdir -p "${M2_BASE}" && \
    echo "[INFO] download maven." && \
    wget -qO- "https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
    | tar -xzf - -C "${M2_BASE}" && \
    ln -s "${M2_HOME}/bin/mvn" /usr/local/bin/mvn && \
    chmod --recursive a+w "${M2_HOME}"/conf/*
# Download MBT
RUN echo "[INFO] Download MBT $MBT_VERSION." && \
    wget -qO- "https://github.com/SAP/cloud-mta-build-tool/releases/download/v${MBT_VERSION}/cloud-mta-build-tool_${MBT_VERSION}_Linux_amd64.tar.gz" | tar -zx -C /usr/local/bin && \
    chown root:root /usr/local/bin/mbt
RUN echo "[INFO] handle users permission." && \
    # Handle users permission
    useradd --home-dir "${MTA_USER_HOME}" --create-home --shell /bin/bash --user-group --uid 1001 --comment 'Cloud MTA Build Tool' --password "$(echo weUseMta |openssl passwd -1 -stdin)" mta && \
    # Allow anybody to write into the images HOME
    chmod a+w "${MTA_USER_HOME}" && \
    # Azure hack, Thank you Microsoft.
    adduser mta sudo
RUN echo "[INFO] install tools and python if needed, otherwise clean." && \
    # Install essential build tools and python, required for building db modules
    # apt-get install --yes --no-install-recommends build-essential python2.7 && \
    apt-get remove --purge --autoremove --yes wget && \
    echo "[INFO] clean up." && \
    rm -rf /var/lib/apt/lists/* && \
    echo "[INFO] DONE!"
ENV PATH=$PATH:./node_modules/.bin HOME=${MTA_USER_HOME}
WORKDIR $MTA_USER_HOME
COPY --chown=mta:mta . .
USER mta
