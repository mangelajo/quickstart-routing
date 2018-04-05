# quickstart-routing

1) Edit config

2) Run setup.sh

```bash
$ ./setup.sh
* The remote interface for 192.168.1.144 is enp0s31f6
* Adding an IP address on the libvirt bridge on the host (192.168.24.123)
* Configuring forwarding from/to the libvirt bridge brovc
nameserver 8.8.8.8
setting up route in 192.168.24.19
setting up route in 192.168.24.8
setting up route in 192.168.24.13
setting up route in 192.168.24.10
overcloud-controller-1 -> 192.168.24.19
overcloud-novacompute-0 -> 192.168.24.8
overcloud-controller-0 -> 192.168.24.13
overcloud-controller-2 -> 192.168.24.10
Password:
add net 192.168.24.0: gateway 192.168.1.144
overcloud-controller-0 | SUCCESS => {
    "changed": false,
    "failed": false,
    "ping": "pong"
}
overcloud-controller-2 | SUCCESS => {
    "changed": false,
    "failed": false,
    "ping": "pong"
}
overcloud-novacompute-0 | SUCCESS => {
    "changed": false,
    "failed": false,
    "ping": "pong"
}
overcloud-controller-1 | SUCCESS => {
    "changed": false,
    "failed": false,
    "ping": "pong"
}
undercloud-node | SUCCESS => {
    "changed": false,
    "failed": false,
    "ping": "pong"
}
===========================================
Config files created:
  * ansible.cfg
  * inventory
  * ~/.ssh/ooo_config

```
