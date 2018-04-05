#!/bin/sh
source config

VIRT_IP=$(dig +short $VIRTHOST)

sudo route add $BRIDGE_NET $VIRT_IP 2>&1 | grep -v exists

ansible -m ping all
