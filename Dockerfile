FROM ubuntu:latest

LABEL maintainer "https://github.com/blacktop"

LABEL malice.plugin.repository = "https://github.com/malice-plugins/avira.git"
LABEL malice.plugin.category="av"
LABEL malice.plugin.mime="*"
LABEL malice.plugin.docker.engine="*"

RUN dpkg --add-architecture i386 \
  && apt-get update \
  && apt-get install -y libc6-i386 file

# Add Files
COPY /run.sh /run.sh
RUN chmod 755 /run.sh

COPY /unattended.inf /unattended.inf
RUN mkdir /home/quarantine/

# Download Avira
ADD http://premium.avira-update.com/package/wks_avira/unix/en/pers/antivir_workstation-pers.tar.gz /tmp

# Install Avira
RUN /tmp/antivir-workstation-pers-3.1.3.5-0/install --inf=/unattended.inf

ADD http://personal.avira-update.com/package/peclkey/win32/int/hbedv.key /usr/lib/AntiVir/guard/avira.key

# Update Avira
RUN /usr/lib/AntiVir/guard/avupdate-guard --product=Guard

# Add EICAR Test Virus File to malware folder
ADD http://www.eicar.org/download/eicar.com.txt /malware/EICAR

WORKDIR /malware

CMD ["/run.sh"]
