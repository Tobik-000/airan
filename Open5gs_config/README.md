# Native Open5GS Profile

This directory contains the complete active Open5GS 5GC configuration captured
from the validated native deployment. The profile uses:

- Serving PLMN `26201`
- Local home PLMN support for `99970` in the NRF
- TAC `7`, SST `1`, and DNN `internet`
- AMF N2 and UPF N3 on `127.0.1.100`
- UE subnet `10.45.0.0/16` through `ogstun`

The configuration set targets Open5GS `2.8.0`. Review schema differences before
using another release.

## Install

On Ubuntu, install the package dependencies and active configuration:

```bash
sudo ./install-packages-ubuntu.sh
sudo ./install-configs.sh
```

`install-configs.sh` backs up the current YAML files under
`/var/backups/airan-open5gs`, installs all 5GC YAML files, enables persistent
`ogstun`/IPv4 forwarding setup, and restarts the native 5GC services.

The forwarding service selects the interface carrying the default IPv4 route.
Override it in `/etc/default/airan-open5gs-network` when required. Forwarding to
private IPv4 destinations is rejected by default to protect management LANs;
set `AIRAN_ALLOW_PRIVATE_NETWORKS=1` only in an isolated laboratory network.
UE traffic arriving through `ogstun` can ping the UE gateway and reach iperf on
port 5201, but cannot reach other services bound to the core host.

The installer places all Open5GS packages on hold at version 2.8.0. Review
configuration compatibility before using `apt-mark unhold` to upgrade them.

## Subscriber Provisioning

Subscriber authentication data is deliberately absent. Provision each SIM
privately using the Open5GS WebUI or another trusted Open5GS provisioning tool.
The subscriber must use the intended HPLMN, authentication values, SST `1`, and
DNN `internet`.

Never add a subscriber CSV, MongoDB dump, IMSI, K, OP, or OPc value to this
repository.

## Validation

```bash
systemctl is-active mongod open5gs-nrfd open5gs-scpd open5gs-amfd \
  open5gs-smfd open5gs-upfd open5gs-ausfd open5gs-udmd open5gs-udrd \
  open5gs-pcfd open5gs-nssfd open5gs-bsfd
ip -4 addr show ogstun
ss -ln -A sctp | grep 127.0.1.100:38412
ss -lnu | grep 127.0.1.100:2152
```
