#!/bin/bash

echo "===> Installing deps..."
apt-get update -qq && apt-get install -yq ca-certificates unzip curl
echo "===> Download Avira DB updates.."
curl -sSL -o /tmp/fusebundlegen.zip "http://install.avira-update.com/package/fusebundlegen/linux_glibc22/en/avira_fusebundlegen-linux_glibc22-en.zip" \
cd /tmp && unzip /tmp/fusebundlegen.zip \
/tmp/fusebundle.bin \
mv install/fusebundle-linux_glibc22-int.zip /opt/avira \
cd /opt/avira && unzip fusebundle-linux_glibc22-int.zip \
echo "===> Clean up unnecessary files..."
apt-get purge -y --auto-remove ca-certificates unzip curl $(apt-mark showauto)
apt-get clean \
rm -rf /var/lib/apt/lists/* /var/cache/apt/archives /tmp/* /var/tmp/*