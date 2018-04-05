#!/bin/sh
source config

VIRT_IP=$(dig +short $VIRTHOST)

SSHCMD="ssh $SSH_OPTS $TRIPLEO_USER@$VIRT_IP"

$SSHCMD hostname >/dev/null|| echo "Can't ssh to $VIRTHOST ($VIRT_IP)" || exit 1

FWD_IFACE=$($SSHCMD "sudo ip a | grep 192.168.1.144 | grep -o \"\w*\$\"")

echo "* The remote interface for $VIRT_IP is $FWD_IFACE"

#
# Configure the VIRTHOST to route traffic back and forth
#

echo "* Adding an IP address on the libvirt bridge on the host ($BRIDGE_ADDR)"
$SSHCMD "sudo ip a add $BRIDGE_ADDR/$BRIDGE_MASK dev $VIRTD_BRIDGE 2>&1 | grep -v exists"

echo "* Configuring forwarding from/to the libvirt bridge $VIRTD_BRIDGE"

$SSHCMD "sudo iptables -C FORWARD -i $FWD_IFACE -o $VIRTD_BRIDGE -s $LOCAL_NET -d $BRIDGE_NET -j ACCEPT || \
         sudo iptables -I FORWARD -i $FWD_IFACE -o $VIRTD_BRIDGE -s $LOCAL_NET -d $BRIDGE_NET -j ACCEPT &&
         sudo iptables -I FORWARD -o $FWD_IFACE -i $VIRTD_BRIDGE -d $LOCAL_NET -s $BRIDGE_NET -j ACCEPT"


#
# Distribute our pubkey to the hosts we want to access
#

cat $YOUR_SSH_PUBKEY | $SSHCMD "$UNDERCLOUD_SSH \"cat >~/your_pubkey\""
cat $YOUR_SSH_PUBKEY | $SSHCMD "$UNDERCLOUD_SSH \"cat >>~/.ssh/authorized_keys\""

#
# Setup routing and pubkey on the cloud nodes
#

$SSHCMD "$UNDERCLOUD_SSH \"echo nameserver 8.8.8.8 | sudo tee /etc/resolv.conf\""
$SSHCMD "$UNDERCLOUD_SSH \"sudo ip r add $LOCAL_NET via $BRIDGE_ADDR\" 2>&1 | grep -v exists"
$SSHCMD "$UNDERCLOUD_SSH \" \
               source stackrc; \
               for ip in \\\$(openstack server list -c Networks -f value | sed 's/ctlplane=//g'); do \
                   echo setting up route in \\\$ip
                   ssh heat-admin@\\\$ip sudo ip r add $LOCAL_NET via $BRIDGE_ADDR 2>&1 | grep -v exists ; \
                   cat ~/your_pubkey | ssh heat-admin@\\\$ip \\\"cat >>~/.ssh/authorized_keys\\\"
               done\""

#
# Create SSH and Ansible config files for the hosts
#

cat > ~/.ssh/ooo_config <<EOF
Host undercloud
    Hostname $UNDERCLOUD_IP
    IdentityFile $YOUR_SSH_PK
    IdentitiesOnly yes
    User stack
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    LogLevel ERROR
EOF

echo "[undercloud]" > inventory
echo "undercloud-node ansible_ssh_host=$UNDERCLOUD_IP ansible_ssh_user=stack ansible_become=true ansible_ssh_private_key=$YOUR_SSH_PK ansible_ssh_extra_args=\"-oIdentitiesOnly=yes\"" >> inventory

echo "" >> inventory
echo "[hosts]" >> inventory

for data in $($SSHCMD "$UNDERCLOUD_SSH \"source stackrc; openstack server list -c Name -c Networks -f csv | sed 's/ctlplane=//g' | grep -v Networks\"");
do
    IFS=',' read -r -a array <<< "$data"
    hostname=$(echo ${array[0]} | sed 's/"//g')
    ip=$(echo ${array[1]} | sed 's/"//g')

    echo $hostname -\> $ip

    cat >> ~/.ssh/ooo_config << EOF
Host $hostname
    Hostname $ip
    User heat-admin
    IdentitiesOnly yes
    IdentityFile $YOUR_SSH_PK
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    LogLevel ERROR
EOF
    echo $hostname ansible_ssh_host=$ip ansible_ssh_user=heat-admin ansible_become=true ansible_ssh_private_key_file=$YOUR_SSH_PK ansible_ssh_extra_args="-oIdentitiesOnly=yes">> inventory

done

cat > ansible.cfg <<EOF
[defaults]
host_key_checking = False
inventory=inventory
EOF


./setup-local.sh

echo "==========================================="
echo "Config files created:"
echo "  * ansible.cfg"
echo "  * inventory"
echo "  * ~/.ssh/ooo_config"

