# OCUDU Setup

The installer clones OCUDU from its upstream GitLab repository and checks out
the validated commit recorded in `version.env`. The upstream source and Docker
files are not duplicated in this repository.

## Native gNB

```bash
./install-ocudu.sh
sudo "${HOME}/ocudu/scripts/ocudu_performance"
sudo gnb -c ../srsRAN_config/gNB/cots_ue.yml
```

To install a systemd service for a selected gNB configuration:

```bash
sudo ./install-gnb-service.sh ../srsRAN_config/gNB/cots_ue.yml
sudo systemctl start ocudu-gnb.service
```

Download the standard UHD image set during installation, then install the
board-specific B210 FPGA file selected for the attached hardware:

```bash
sudo ./install-uhd-image.sh ../UHD_images/Kintex7/usrp_b210_fpga.bin
```

Do not install an image for a different B210 variant.

The COTS profile expects the gNB B210 to receive a valid external 10 MHz
reference. Change the clock setting only when the physical clock topology is
different.

## Docker Open5GS Core

Docker Open5GS is used for the ZMQ and srsUE profiles. It is an alternative to
the native Open5GS core.

Install Docker Engine and the Compose plugin on Ubuntu if they are absent:

```bash
sudo apt-get update
sudo apt-get install docker.io docker-compose-v2
sudo usermod -aG docker "$USER"
```

Log out and back in after changing group membership. Verify both commands:

```bash
docker --version
docker compose version
```

```bash
install -m 0600 subscriber_db.csv.example subscriber_db.csv
# Edit subscriber_db.csv privately.
./start-docker-core.sh
```

Stop it before starting native Open5GS:

```bash
./stop-docker-core.sh
```

`subscriber_db.csv` is ignored by Git. Never commit operational subscriber
credentials or replace the tracked example placeholders with real values. The
launcher uses an external build context and a read-only runtime bind mount so
the private CSV is not copied into a Docker image layer.
