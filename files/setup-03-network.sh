#!/bin/bash
# Copyright 2021 VMware, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-2

# Setup Networking

set -euo pipefail

echo -e "\e[92mConfiguring Static IP Address ..." > /dev/console

NETWORK_CONFIG_FILE=$(ls /etc/systemd/network | grep .network)
cat > /etc/systemd/network/${NETWORK_CONFIG_FILE} << __CUSTOMIZE_PHOTON__
[Match]
Name=e*

[Network]
Address=${IP_ADDRESS}/${NETMASK}
Gateway=${GATEWAY}
DNS=${DNS_SERVER}
Domain=${DNS_DOMAIN}
__CUSTOMIZE_PHOTON__

# Remove default symlink to prevent reverting back to local DNS stub resolver
rm -f /etc/resolv.conf
cat > /etc/resolv.conf <<EOF
nameserver ${DNS_SERVER}
search ${DNS_DOMAIN}
EOF

echo -e "\e[92mConfiguring NTP ..." > /dev/console
cat > /etc/systemd/timesyncd.conf << __CUSTOMIZE_PHOTON__

[Match]
Name=e*

[Time]
NTP=${NTP_SERVER}
__CUSTOMIZE_PHOTON__

echo -e "\e[92mConfiguring hostname ..." > /dev/console
echo "${IP_ADDRESS} ${HOSTNAME}" >> /etc/hosts
hostnamectl set-hostname ${HOSTNAME}

echo -e "\e[92mRestarting Network ..." > /dev/console
systemctl restart systemd-networkd

echo -e "\e[92mRestarting Timesync ..." > /dev/console
systemctl restart systemd-timesyncd

# Disables cloud-init which ensures FQDN hostname is preserved upon reboot
touch /etc/cloud/cloud-init.disabled