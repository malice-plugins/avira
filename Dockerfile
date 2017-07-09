FROM ubuntu:latest

LABEL maintainer "https://github.com/blacktop"

LABEL malice.plugin.repository = "https://github.com/malice-plugins/avira.git"
LABEL malice.plugin.category="av"
LABEL malice.plugin.mime="*"
LABEL malice.plugin.docker.engine="*"

RUN dpkg --add-architecture i386 \
  && apt-get update \
  && apt-get install -y libc6-i386 file unzip

# Add Files
COPY scancl-linux_glibc22.tar.gz /tmp
COPY avira_fusebundlegen-linux_glibc22-en.zip /tmp
COPY avira.key /tmp/hbedv.key

WORKDIR /tmp

RUN tar zxvf /tmp/scancl-linux_glibc22.tar.gz
RUN unzip /tmp/avira_fusebundlegen-linux_glibc22-en.zip \
  && ls -lah \
  && /tmp/fusebundle.bin \
  && mv install/fusebundle-linux_glibc22-int.zip /tmp/scancl-1.9.161.2/ \
  && cd /tmp/scancl-1.9.161.2/ \
  && unzip fusebundle-linux_glibc22-int.zip

ADD http://personal.avira-update.com/package/peclkey/win32/int/hbedv.key /tmp/scancl-1.9.161.2/
