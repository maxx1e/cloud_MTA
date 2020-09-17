FROM openjdk:11-jdk-slim

# Build time variables
ARG MTA_USER_HOME=/home/mta
ARG MBT_VERSION=1.0.16
ARG NODE_VERSION=v12.18.3
ARG MAVEN_VERSION=3.6.3
ENV M2_HOME=/opt/maven/apache-maven-${MAVEN_VERSION}

# Download required env tools
RUN apt-get update && \
    apt-get install --yes --no-install-recommends curl git sudo build-essential && \

    # Change security level as the SAP npm repo doesnt support buster new security upgrade
    # the default configuration for OpenSSL in Buster explicitly requires using more secure ciphers and protocols,
    # and the server running at http://npm.sap.com/ is running software configured to only provide insecure, older ciphers.
    # This causes SSL connections using OpenSSL from a Buster based installation to fail
    # Should be remove once SAP npm repo will patch the security level
    # see - https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=912759
    sed -i -E 's/(CipherString\s*=\s*DEFAULT@SECLEVEL=)2/\11/' /etc/ssl/openssl.cnf && \

    # Install node
    NODE_HOME=/opt/nodejs; mkdir -p ${NODE_HOME} && \
    curl --fail --silent --output - "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.gz" \
     | tar -xzv -f - -C "${NODE_HOME}" && \
    ln -s "${NODE_HOME}/node-${NODE_VERSION}-linux-x64/bin/node" /usr/local/bin/node && \
    ln -s "${NODE_HOME}/node-${NODE_VERSION}-linux-x64/bin/npm" /usr/local/bin/npm && \
    ln -s "${NODE_HOME}/node-${NODE_VERSION}-linux-x64/bin/npx" /usr/local/bin/ && \
    npm install --prefix /usr/local/ -g grunt-cli && \
    # Config NPM
    npm config set @sap:registry https://npm.sap.com --global && \
    # install ui5-cli temporay solution
     npm install --prefix /usr/local/ -g @ui5/cli && \

    # Update Maven home
    M2_BASE="$(dirname ${M2_HOME})" && \
    mkdir -p "${M2_BASE}" && \
    curl --fail --silent --output - "https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
    | tar -xzvf - -C "${M2_BASE}" && \
     ln -s "${M2_HOME}/bin/mvn" /usr/local/bin/mvn && \
     chmod --recursive a+w "${M2_HOME}"/conf/* && \

     # Download MBT
     curl -L "https://github.com/SAP/cloud-mta-build-tool/releases/download/v${MBT_VERSION}/cloud-mta-build-tool_${MBT_VERSION}_Linux_amd64.tar.gz" | tar -zx -C /usr/local/bin && \
     chown root:root /usr/local/bin/mbt && \

     # Handle users permission
     useradd --home-dir "${MTA_USER_HOME}" \
                 --create-home \
                 --shell /bin/bash \
                 --user-group \
                 --uid 1001 \
                 --comment 'Cloud MTA Build Tool' \
                 --password "$(echo weUseMta |openssl passwd -1 -stdin)" mta && \
         # allow anybody to write into the images HOME
         chmod a+w "${MTA_USER_HOME}" && \
         usermod -aG sudo mta && \
         echo >> 'mta ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers && \
         apt-get remove --purge --autoremove --yes curl && \
         rm -rf /var/lib/apt/lists/*

ENV PATH=$PATH:./node_modules/.bin HOME=${MTA_USER_HOME}
WORKDIR /project
USER mta
