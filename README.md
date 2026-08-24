# AIRAN 5G SA Deployment

This repository contains the reproducible configuration used for the AIRAN
OCUDU, srsUE, and Open5GS testbed. It supports these deployment profiles:

- ZMQ gNB and srsUE with the OCUDU Docker Open5GS core
- Band-3 FDD gNB and srsUE with B210 radios
- Band-n1 OCUDU gNB and a COTS UE with native Open5GS

## Clone

```bash
git clone https://github.com/Tobik-000/airan.git airan_setup
cd airan_setup
```

## Host Setup

Install the gNB and native Open5GS core on the gNB host:

```bash
./setup.bash gnb-host
```

Install srsUE on the UE host:

```bash
./setup.bash ue-host
```

The installers use the validated source revisions:

- OCUDU `52aeaddf4a7e9157fa32122c1f8ab66687dbedac`
- srsRAN 4G `6bcbd9e5bf8686aa7085202cd847c5ddd64a9c16`
- Native Open5GS package profile `2.8.0`
- OCUDU Docker Open5GS `2.7.6`
- MongoDB `8.0`

Read `OCUDU_setup/README.md` and `Open5gs_config/README.md` before starting a
core. Docker Open5GS and native Open5GS are alternative deployments and must
not run at the same time.

## Configuration Layout

- `srsRAN_config/gNB`: ZMQ, band-3, and band-n1 gNB profiles
- `srsRAN_config/UE`: ZMQ and band-3 srsUE profiles
- `Open5gs_config`: complete native Open5GS 5GC service configuration
- `OCUDU_setup`: pinned OCUDU build, Docker-core, and gNB service helpers
- `UHD_images`: board-specific B210 FPGA images

Install the board-specific FPGA image only after identifying the attached B210
variant. The images in `UHD_images` are not interchangeable.

## Secrets

No operational subscriber database, IMSI, authentication key, OP/OPc value, or
MongoDB archive belongs in Git. Private subscriber data must be provisioned on
each deployment host. The repository ignores `OCUDU_setup/subscriber_db.csv`
and Open5GS database archives by default.

Some legacy srsUE profiles contain OCUDU's public demo subscriber values. Do
not use those public examples as operational credentials.
