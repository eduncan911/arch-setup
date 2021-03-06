#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage:"
    echo "  chroot.sh HOST_NAME DOMAIN PASS NETWORK_DEVICES"
    exit 3
fi

HOST_NAME="$1"
DOMAIN="$2"
PASSWD_ROOT="$3"
NETWORK_DEVICES="$4"
[ "${NETWORK_DEVICES}" == "" ] && NETWORK_DEVICES="eth0"

echo "######################################"
echo "## pacman -Sy sudo git openssh curl wget htop tree vim"
echo "######################################"
pacman --noconfirm -Syu sudo git openssh curl wget htop tree vim

echo "######################################"
echo "## localization for en_US, UTF8, GMT -0"
echo "######################################"
ln -sf /usr/share/zoneinfo/GMT /etc/localtime
hwclock --systohc   # sync time
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "######################################"
echo "## ${HOST_NAME}.${DOMAIN} > /etc/hostname /etc/hosts"
echo "######################################"
echo "${HOST_NAME}" > /etc/hostname
cat > /etc/hosts << EOF
127.0.0.1  localhost
::1        localhost
127.0.1.1  ${HOST_NAME}.${DOMAIN} ${HOST_NAME}
EOF

echo "######################################"
echo "## configure DHCP for ${NETWORK_DEVICES}"
echo "######################################"
for n in ${NETWORK_DEVICES//,/ }; do
  [ "${n}" == "lo" ] && continue
  
  cat > "/etc/systemd/network/20-${n}.network" << EOF
[Match]
Name=${n}

# Uncomment the following lines
# for a static network configuration.

#[Route]
#Gateway=10.88.88.1
#Metric=10

#[Address]
#Address=127.0.1.1/24

[Network]
#DNS=10.88.88.1
DHCP=ipv4

# Uncomment to specify the routing order
#[DHCP]
#RouteMetric=10
EOF
done

echo "######################################"
echo "## enable systemd-networkd.service"
echo "######################################"
systemctl enable systemd-networkd.service

echo "######################################"
echo "## systemd-boot: bootctl --path=/boot install"
echo "######################################"
bootctl --path=/boot install

echo "######################################"
echo "## passwd root"
echo "######################################"
echo "root:${PASSWD_ROOT}" | chpasswd

echo "######################################"
echo "## sudoers for wheel"
echo "######################################"
echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
