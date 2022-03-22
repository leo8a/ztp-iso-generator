#!/bin/bash


# 1) Create virtual validation network for SNOs
kcli create network -c 172.16.100.0/24 --domain validations.e2e.bos.redhat.com --nodhcp validations-net
kcli list network


# 2) Install DHCP, DNS, and NTP servers
dnf install -y dnsmasq bind-utils chrony
rm -rf /opt/validations; mkdir -pv /opt/validations


# 3) Configure DHCP, and DNS servers
cat <<EOF > /opt/validations/dnsmasq.conf
bind-dynamic
interface=validations-net
except-interface=lo
log-queries
log-dhcp
bogus-priv
dhcp-authoritative
dhcp-lease-max=81
user=dnsmasq
group=dnsmasq

# DHCP
dhcp-range=validations-net,172.16.100.11,172.16.100.20,255.255.255.0,4h
dhcp-option=validations-net,option:dns-server,172.16.100.1
dhcp-hostsfile=/opt/validations/hosts.hostsfile
dhcp-leasefile=/opt/validations/hosts.leases

# DNS
domain=validations.e2e.bos.redhat.com

address=/apps.ztp-sno.validations.e2e.bos.redhat.com/172.16.100.5
host-record=api.ztp-sno.validations.e2e.bos.redhat.com,172.16.100.5

address=/apps.pre-staging-sno.validations.e2e.bos.redhat.com/172.16.100.6
host-record=api-int.pre-staging-sno.validations.e2e.bos.redhat.com,172.16.100.6

host-record=$(hostname -f),172.16.100.1
EOF
cat <<EOF > /opt/validations/hosts.hostsfile
de:ad:be:ff:00:05,ztp-sno,172.16.100.5
de:ad:be:ff:00:06,pre-staging-sno,172.16.100.6
EOF
cat <<EOF > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

# Cluster Services
172.16.100.5        api.ztp-sno.validations.e2e.bos.redhat.com
172.16.100.5        api-int.ztp-sno.validations.e2e.bos.redhat.com

172.16.100.6        api.pre-staging-sno.validations.e2e.bos.redhat.com
172.16.100.6        api-int.pre-staging-sno.validations.e2e.bos.redhat.com

# Cluster Nodes
172.16.100.5        ztp-sno.validations.e2e.bos.redhat.com
172.16.100.6        pre-staging-sno.validations.e2e.bos.redhat.com
EOF
cat <<EOF > /etc/chrony.conf
server clock.corp.redhat.com iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
bindcmdaddress 0.0.0.0
allow 172.16.100.0/24
EOF

setenforce 0
rm -f /opt/validations/hosts.leases ; touch /opt/validations/hosts.leases


# 4) Start/Enable DNS, and NTP servers as Systemd units
cat <<EOF > /etc/systemd/system/dnsmasq-validation.service
[Unit]
Description=DNS server for Openshift 4 Virt clusters.
After=network.target
[Service]
User=root
Group=root
ExecStart=/usr/sbin/dnsmasq -k --conf-file=/opt/validations/dnsmasq.conf
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload

systemctl enable chronyd --now
systemctl enable dnsmasq-validation --now

systemctl restart chronyd
systemctl restart dnsmasq-validation


# 5) Validate created records

# 5.1) ztp-sno
dig +short ztp-sno.validations.e2e.bos.redhat.com @172.16.100.1
dig +short api.ztp-sno.validations.e2e.bos.redhat.com @172.16.100.1
dig +short api-int.ztp-sno.validations.e2e.bos.redhat.com @172.16.100.1

# 5.2) pre-staging-sno
dig +short pre-staging-sno.validations.e2e.bos.redhat.com @172.16.100.1
dig +short api.pre-staging-sno.validations.e2e.bos.redhat.com @172.16.100.1
dig +short api-int.pre-staging-sno.validations.e2e.bos.redhat.com @172.16.100.1
