# Low-code Automations

A self-hosted, low-code home/edge automation platform built around [Node-RED](https://nodered.org/), fronted by NGINX with TLS, and backed by etcd for dynamic configuration. It includes a camera automation module that provisions and manages Raspberry Pi–based motion-detection cameras via Terraform.

## Architecture

The stack runs as three Docker containers orchestrated by Docker Compose:

| Service   | Image                          | Role                                                                 |
|-----------|--------------------------------|----------------------------------------------------------------------|
| `nodered` | `nodered/node-red:latest`      | Low-code flow engine where automations are built and run (port 1880).|
| `etcd`    | `ghcr.io/fvilarinho/etcd:1.2.0`| Key-value store holding dynamic NGINX configuration.                 |
| `nginx`   | `ghcr.io/fvilarinho/nginx:1.2.0`| Reverse proxy terminating TLS and forwarding to Node-RED.           |

```
Client ──HTTPS(443)/HTTP(80)──▶ nginx ──proxy──▶ nodered:1880
                                  │
                                  └── config sourced from etcd
```

NGINX proxies all traffic to Node-RED and upgrades WebSocket connections (required by the Node-RED editor and dashboards).

## Project Structure

```
.
├── docker-compose.yml            # Service definitions
├── start.sh                      # Convenience script to bring the stack up
├── nginx/
│   ├── etc/
│   │   ├── settings.json          # Listen ports (80 / 443)
│   │   ├── conf.d/
│   │   │   └── default.conf.template  # Reverse-proxy vhost template
│   │   └── ssl/                   # TLS cert (automation.pem) and key (automation.key)
│   └── bin/
│       └── certgen.sh             # Issues a Let's Encrypt cert via certbot (DNS-01)
└── nodered/
    ├── settings.js               # Node-RED runtime settings
    └── cameras/                  # Camera automation module
        ├── deploy.sh             # Provisions cameras with Terraform
        ├── iac/                  # Terraform (null_resource remote-exec/file provisioners)
        │   ├── main.tf
        │   └── variables.tf
        ├── etc/
        │   ├── environment       # Shell env sourced by camera scripts
        │   └── flows.json        # Node-RED flows for the camera module
        └── bin/                  # Scripts deployed to each camera host
            ├── stats.sh          # Aggregates model/cpu/memory/disk/temp/state as JSON
            ├── cpu.sh / cpu.py   # CPU usage
            ├── memory.sh         # Memory usage
            ├── disk.sh           # Disk usage
            ├── temp.sh           # SoC temperature (vcgencmd)
            ├── model.sh          # Detected USB camera model
            └── motion/           # motion daemon control
                ├── start.sh
                ├── stop.sh
                ├── checkIfItsOn.sh
                └── motion.conf.template
```

## Prerequisites

- [Docker](https://www.docker.com/) with the Compose plugin
- [certbot](https://certbot.eff.org/) — only if you want to issue TLS certificates with `nginx/bin/certgen.sh`
- [Terraform](https://www.terraform.io/) — only if you use the camera automation module
- Target camera hosts (e.g. Raspberry Pi running Debian/Raspberry Pi OS) reachable over SSH, for the camera module

## Getting Started

### 1. Configure NGINX

Create the vhost config from the template and set your domain:

```bash
cp nginx/etc/conf.d/default.conf.template nginx/etc/conf.d/default.conf
# edit nginx/etc/conf.d/default.conf and replace <automation_server_domain>
```

### 2. Provide TLS certificates

Place your certificate and key at:

- `nginx/etc/ssl/automation.pem`
- `nginx/etc/ssl/automation.key`

Or generate them with Let's Encrypt (DNS-01 challenge):

```bash
cd nginx/bin
export AUTOMATION_SERVER_DOMAIN=your.domain.com
export CERTGEN_EMAIL=you@example.com
./certgen.sh
```

The script issues the certificate and copies it into `nginx/etc/ssl/`.

### 3. Start the stack

```bash
./start.sh
```

This runs `docker compose up -d`. Once up, access Node-RED through NGINX at `https://<your-domain>/`.

To stop:

```bash
docker compose down
```

## Camera Automation Module

The `nodered/cameras` module provisions one or more camera hosts and installs monitoring and motion-detection tooling on them. Each host gets a set of scripts that report health metrics (`stats.sh` returns model, CPU, memory, disk, temperature, and motion state as JSON) and control the [motion](https://motion-project.github.io/) daemon.

### Configure cameras

Create `nodered/cameras/iac/terraform.tfvars` (gitignored) based on `variables.tf`:

```hcl
cameras = [
  {
    name        = "front-door"
    ip          = "192.168.1.50"
    user        = "pi"
    pass        = "your-password"
    install_dir = "/home/pi/camera"
  }
]
```

### Deploy

```bash
cd nodered/cameras
./deploy.sh
```

`deploy.sh` runs `terraform init`, `plan`, and `apply`. The Terraform config uses `null_resource` provisioners to:

1. Install dependencies (`python3`, `python3-psutil`, `motion`, and utilities) on each host.
2. Copy the monitoring and motion-control scripts into the host's install directory.
3. Copy the environment file to `/etc/camera/environment` and make scripts executable.

Node-RED flows for interacting with these cameras are defined in `nodered/cameras/etc/flows.json`.

## Configuration Reference

| File                                   | Purpose                                                        |
|----------------------------------------|----------------------------------------------------------------|
| `nginx/etc/settings.json`              | HTTP (`80`) and HTTPS (`443`) listen ports.                    |
| `nginx/etc/conf.d/default.conf`        | Reverse-proxy vhost (generated from the template).             |
| `nodered/settings.js`                  | Node-RED runtime configuration.                                |
| `nodered/cameras/etc/environment`      | Command paths and `INSTALL_DIR` sourced by camera scripts.     |
| `nodered/cameras/iac/terraform.tfvars` | Camera host inventory (create locally; not committed).         |

## Environment Variables

### Certificate generation (`nginx/bin/certgen.sh`)

Set these before running the script to issue a Let's Encrypt certificate:

| Variable                  | Required | Description                                                              |
|---------------------------|----------|--------------------------------------------------------------------------|
| `AUTOMATION_SERVER_DOMAIN`| Yes      | Domain the certificate is issued for (also used as the certbot path).    |
| `CERTGEN_EMAIL`           | Yes      | Email address registered with Let's Encrypt for the certificate.         |

### Camera scripts (`nodered/cameras/etc/environment`)

This file is sourced by every camera script (via `source /etc/camera/environment`) and is deployed to each camera host at `/etc/camera/environment`. `INSTALL_DIR` is the only value you typically set; the `*_CMD` variables are auto-resolved from `PATH` with `which` and only need overriding if a binary lives in a non-standard location.

| Variable      | Default              | Description                                                     |
|---------------|----------------------|-----------------------------------------------------------------|
| `INSTALL_DIR` | `$HOME/camera`       | Directory on the camera host where scripts are installed.       |
| `MOTION_CMD`  | `$(which motion)`    | Path to the `motion` daemon binary.                             |
| `PYTHON_CMD`  | `$(which python3)`   | Path to the Python 3 interpreter (used by `cpu.py`).            |
| `FREE_CMD`    | `$(which free)`      | Path to `free` (memory metrics).                                |
| `DF_CMD`      | `$(which df)`        | Path to `df` (disk metrics).                                    |
| `VCGEN_CMD`   | `$(which vcgencmd)`  | Path to `vcgencmd` (Raspberry Pi SoC temperature).             |
| `SED_CMD`     | `$(which sed)`       | Path to `sed`.                                                  |
| `AWK_CMD`     | `$(which awk)`       | Path to `awk`.                                                  |
| `GREP_CMD`    | `$(which grep)`      | Path to `grep`.                                                 |
| `LSUSB_CMD`   | `$(which lsusb)`     | Path to `lsusb` (USB camera model detection).                  |

### Internal / runtime

These are resolved automatically and are not meant to be set by the user:

| Variable      | Where              | Description                                                        |
|---------------|--------------------|--------------------------------------------------------------------|
| `DOCKER_CMD`  | `start.sh`         | Resolved via `which docker`; used to run `docker compose up -d`.  |
| `CERTBOT_CMD` | `certgen.sh`       | Resolved via `which certbot`; used to issue the certificate.      |
| `TERRAFORM_CMD`| `cameras/deploy.sh`| Resolved via `which terraform`; used to run init/plan/apply.     |
| `${DEVICE_ID}`| `motion.conf.template` | Substituted at runtime by `motion/start.sh` with the detected `/dev/video*` device. |

## Notes

Sensitive and generated files are excluded from version control (see `.gitignore`), including TLS keys/certs, the generated NGINX vhost, the Node-RED SSH key, and Terraform state and `.tfvars`. Configure these locally per deployment.

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.
