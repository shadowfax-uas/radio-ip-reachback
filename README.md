# Raspberry Pi Setup Package

This package is designed to prepare an Ubuntu-based Raspberry Pi for a TAK/CoT forwarding setup.

## Overview

- `setup.sh` is the installation entrypoint.
- `setup-files/` contains all configuration resources and certificates required by the install.
- The script installs required packages, replaces system config files, enables services, and connects the Pi to a ZeroTier network.

## Package Contents

- `setup.sh`
  - Updates the system package lists.
  - Installs `nftables`, `curl`, and `openssh-server`.
  - Copies the `setup-files/tak` folder to `/etc/tak`.
  - Copies `cot-forwarding.service` into `/etc/systemd/system/`.
  - Replaces `/etc/nftables.conf` with `setup-files/nftables.conf`.
  - Replaces existing Netplan YAML files with `setup-files/silvus.yaml`.
  - Enables IPv4 forwarding in `/etc/sysctl.conf`.
  - Reloads systemd, restarts/enables `cot-forwarding.service`, `nftables`, and SSH.
  - Allows SSH through `ufw`.
  - Installs ZeroTier and prompts for a ZeroTier network ID.
  - Joins the specified ZeroTier network and reboots the system.

- `setup-files/`
  - `cot-forwarding.service` - systemd service file for CoT UDP-to-TLS forwarding.
  - `nftables.conf` - nftables ruleset for NAT/masquerade and basic filtering.
  - `silvus.yaml` - Netplan network configuration for `eth0`.
  - `tak/certs/` - certificate materials required by the forwarding service.

## Usage

1. Copy or unzip the entire package onto the Raspberry Pi.
2. From the package root, run:

```bash
sudo bash setup.sh
```

3. When prompted, enter the ZeroTier Network ID for the Pi to join.
4. The script will reboot the Pi after installation completes.

## Requirements

- Ubuntu on Raspberry Pi (or another Debian/Ubuntu-based distribution).
- Network connectivity during installation.
- `sudo` privileges.
- A valid ZeroTier Network ID.

## Important Notes

- The service file expects `socat` to be available at `/usr/bin/socat`.
  - If `socat` is not installed on the system, the `cot-forwarding.service` will fail to start.
  - Consider installing `socat` manually or adding it to `setup.sh` if needed.

- The script replaces existing Netplan YAML files and `/etc/nftables.conf`.
  - This is intentional for the desired network and firewall configuration.
  - If you have custom existing network or firewall settings, back them up before running the script.

- `setup.sh` enables SSH access and opens the SSH port in UFW.

- The script runs `sudo reboot` at the end, so save any work before executing.

## Included Certificates

The `setup-files/tak/certs/` directory includes the following files:

- `Battle_Lab_Airboss.crt`
- `Battle_Lab_Airboss.key`
- `Battle_Lab_Airboss.key.dec`
- `Battle_Lab_Airboss.p12`
- `Battle_Lab_Airboss.pem`

The service uses `Battle_Lab_Airboss.pem` and `Battle_Lab_Airboss.key.dec` for TLS.

## Packaging for Delivery

When delivering this package as a ZIP file, include the full directory structure exactly as shown:

- `setup.sh`
- `setup-files/cot-forwarding.service`
- `setup-files/nftables.conf`
- `setup-files/silvus.yaml`
- `setup-files/tak/certs/*`

This ensures the installation script can find and copy the required resources.
