####################################################
# GOLANG BUILDER
####################################################
FROM golang:1.11 as go_builder

COPY . /go/src/github.com/malice-plugins/avira
WORKDIR /go/src/github.com/malice-plugins/avira
RUN go get -u github.com/golang/dep/cmd/dep && dep ensure
RUN go build -ldflags "-s -w -X main.Version=v$(cat VERSION) -X main.BuildTime=$(date -u +%Y%m%d)" -o /bin/avscan

####################################################
# PLUGIN BUILDER
####################################################
FROM ubuntu:bionic

LABEL maintainer "https://github.com/blacktop"

LABEL malice.plugin.repository = "https://github.com/malice-plugins/avira.git"
LABEL malice.plugin.category="av"
LABEL malice.plugin.mime="*"
LABEL malice.plugin.docker.engine="*"

# Create a malice user and group first so the IDs get set the same way, even as
# the rest of this may change over time.
RUN groupadd -r malice \
  && useradd --no-log-init -r -g malice malice \
  && mkdir /malware \
  && chown -R malice:malice /malware

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

ARG AVIRA_KEY
ENV AVIRA_KEY=$AVIRA_KEY

# COPY hbedv.key /opt/avira
RUN if [ "x$AVIRA_KEY" != "x" ]; then \
  echo "===> Adding Avira License Key..."; \
  mkdir -p /opt/avira; \
  echo -n "$AVIRA_KEY" | base64 -d > /opt/avira/hbedv.key ; \
  fi

RUN mkdir -p /opt/malice
COPY update.sh /opt/malice/update

# Add EICAR Test Virus File to malware folder
ADD http://www.eicar.org/download/eicar.com.txt /malware/EICAR

COPY --from=go_builder /bin/avscan /bin/avscan

WORKDIR /malware

ENTRYPOINT ["/bin/avscan"]
CMD ["--help"]
