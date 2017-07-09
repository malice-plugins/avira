FROM ubuntu:latest

LABEL maintainer "https://github.com/blacktop"

LABEL malice.plugin.repository = "https://github.com/malice-plugins/avira.git"
LABEL malice.plugin.category="av"
LABEL malice.plugin.mime="*"
LABEL malice.plugin.docker.engine="*"

RUN apt-get -q update && apt-get install -yq libc6-i386

# Add Files
COPY /run.sh /run.sh
RUN chmod 755 /run.sh

COPY /unattended.inf /unattended.inf
RUN mkdir /home/quarantine/

# Download Avira
ADD http://premium.avira-update.com/package/wks_avira/unix/en/pers/antivir_workstation-pers.tar.gz /
RUN tar -zxvf /antivir_workstation-pers.tar.gz

# Install Avira
RUN /antivir-workstation-pers-3.1.3.5-0/install --inf=/unattended.inf

ADD http://personal.avira-update.com/package/peclkey/win32/int/hbedv.key /usr/lib/AntiVir/guard/avira.key

# Update Avira
RUN /usr/lib/AntiVir/guard/avupdate-guard --product=Guard

WORKDIR /malware

CMD ["/run.sh"]
