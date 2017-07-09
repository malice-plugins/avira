FROM ubuntu:xenial

LABEL maintainer "https://github.com/blacktop"

LABEL malice.plugin.repository = "https://github.com/malice-plugins/avira.git"
LABEL malice.plugin.category="av"
LABEL malice.plugin.mime="*"
LABEL malice.plugin.docker.engine="*"

RUN buildDeps='ca-certificates file unzip curl' \
  && dpkg --add-architecture i386 \
  && apt-get update \
  && apt-get install -yq $buildDeps libc6-i386 \
  && echo "===> Install Avira..." \
  && curl -sSL "http://professional.avira-update.com/package/scancl/linux_glibc22/en/scancl-linux_glibc22.tar.gz" \
		| tar -xzf - -C /tmp \
  && mv /tmp/scancl* /opt/avira \
  && curl -sSL -o /tmp/fusebundlegen.zip "http://install.avira-update.com/package/fusebundlegen/linux_glibc22/en/avira_fusebundlegen-linux_glibc22-en.zip" \
  && cd /tmp && unzip /tmp/fusebundlegen.zip \
  && /tmp/fusebundle.bin \
  && mv install/fusebundle-linux_glibc22-int.zip /opt/avira \
  && cd /opt/avira && unzip fusebundle-linux_glibc22-int.zip \
  && echo "===> Clean up unnecessary files..." \
  && apt-get purge -y --auto-remove $buildDeps \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

COPY hbedv.key /opt/avira

# Add EICAR Test Virus File to malware folder
ADD http://www.eicar.org/download/eicar.com.txt /malware/EICAR
