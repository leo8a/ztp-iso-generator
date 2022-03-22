#!/bin/bash


# 1) Delete VMs, network
kcli delete vm ztp-sno
kcli delete vm pre-staging-sno
kcli delete network validations-net


# 2) Delete other artifacts
systemctl disable chronyd --now
systemctl disable dnsmasq-validation --now
rm -rf /etc/chrony.conf /opt/validations
systemctl daemon-reload
