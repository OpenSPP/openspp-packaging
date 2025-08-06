# OpenSPP Packaging

This repository contains the packaging infrastructure for OpenSPP (Open Source Social Protection Platform), implementing a robust vendored source tarball strategy for managing complex dependencies.

## Overview

OpenSPP uses a **manifest-based vendoring approach** to ensure reproducible builds across all package formats:

- **Python Package** (wheel/sdist) - For pip installation
- **RPM Package** - For Red Hat/Fedora/CentOS systems
- **DEB Package** - For Debian/Ubuntu systems
- **Windows Installer** - NSIS-based installer (buildable on Linux with Wine)
- **Docker Image** - Containerized deployment

## Quick Start

### Prerequisites

- Python 3.10+ (we recommend 3.11 via pyenv)
- Git
- uv (Python package manager - install via https://github.com/astral-sh/uv)
- pyenv (optional but recommended for Python version management)

### Setting Up

```bash
# Clone the repository
git clone https://github.com/OpenSPP/openspp-packaging.git
cd openspp-packaging

# Run automated setup (installs uv, sets Python version, creates venv)
./setup-env.sh

# If you get "uv: command not found", run the quick fix:
./quick-fix.sh

# Or manual setup:
pyenv local 3.11                    # Set Python version
uv venv .venv                        # Create virtual environment
source .venv/bin/activate            # Activate it
uv pip install -r requirements-dev.txt  # Install dev dependencies

# Vendor all dependencies
python vendorize.py --lock
```

**Note**: On macOS with pyenv, `uv` might be installed in the Python environment but not globally available. The setup script handles this automatically, or you can run `./quick-fix.sh` to fix PATH issues.

### Building Packages

```bash
# Create source tarball
python vendorize.py --tarball 17.0.2

# The tarball contains everything needed for reproducible builds
# CI/CD will build all package formats from this tarball
```

### Updating Dependencies

```bash
# 1. Edit dependencies.yaml to update versions/branches
vim dependencies.yaml

# 2. Update lockfile and vendor
python vendorize.py --lock

# 3. Test locally
# ... your tests ...

# 4. Commit both files
git add dependencies.yaml dependencies.lock.yaml
git commit -m "Update dependency versions"
```

## Installation Methods

> **Note**: External package repositories (PyPI, Docker Hub) are not yet enabled. All packages are currently distributed via GitHub Releases.

### 1. Python Package (from GitHub Release)

```bash
# Download the latest release
gh release download v17.0.1

# Install the wheel
pip install openspp-17.0.1-py3-none-any.whl
```

### 2. RPM Installation (Red Hat/Fedora/CentOS)

```bash
sudo dnf install openspp-17.0.1-1.noarch.rpm
sudo systemctl start openspp
```

### 3. DEB Installation (Debian/Ubuntu)

```bash
sudo dpkg -i openspp_17.0.1_all.deb
sudo apt-get install -f  # Install dependencies
sudo systemctl start openspp
```

### 4. Windows Installation

Run the `openspp-17.0.1-setup.exe` installer and follow the wizard.

**Note**: Windows installers can be built on Linux using Wine, eliminating the need for Windows build machines.

### 5. Docker Deployment

```bash
# Download Docker image from GitHub Release
gh release download v17.0.1 --pattern "*.tar"

# Load the Docker image
docker load -i openspp-docker-17.0.1.tar

# Run the container
docker run -d -p 8069:8069 openspp/openspp:17.0

# Or use Docker Compose (after loading image)
cd setup/docker
docker-compose up -d
```

## Architecture

### Dependency Management

All dependencies are defined in `dependencies.yaml`:

```yaml
odoo:
  url: "https://github.com/odoo/odoo.git"
  ref: "17.0"

addons:
  openspp_modules:
    url: "https://github.com/OpenSPP/openspp-modules.git"
    ref: "17.0"
  
  oca_server_tools:
    url: "https://github.com/OCA/server-tools.git"
    ref: "17.0"
    modules:  # Selective module inclusion
      - "base_multi_image"
```

The `vendorize.py` script:
1. Resolves all refs to commit SHAs (creates `dependencies.lock.yaml`)
2. Clones all repositories at locked commits
3. Creates a vendor directory with all dependencies
4. Can generate a source tarball for distribution

## Directory Structure

```
openspp-packaging/
├── dependencies.yaml      # Dependency manifest (source of truth)
├── dependencies.lock.yaml # Locked versions (auto-generated)
├── vendorize.py          # Vendoring script
├── vendor/               # Vendored dependencies (git-ignored)
│   ├── odoo/            # Odoo framework
│   └── addons/          # All addon modules
├── requirements.txt      # Python dependencies
├── setup.py             # Python package setup
├── setup/               # Packaging configurations
│   ├── debian/          # Debian packaging
│   ├── rpm/             # RPM packaging
│   ├── windows/         # Windows installer
│   └── docker/          # Docker configuration
└── .github/workflows/   # GitHub Actions CI/CD
    ├── build-packages.yml
    └── release.yml
```

## Configuration

After installation, OpenSPP configuration file is located at:

- **Linux**: `/etc/openspp/openspp.conf`
- **Windows**: `C:\Program Files\OpenSPP\openspp.conf`
- **Docker**: `/etc/openspp/openspp.conf` (in container)

Example configuration:

```ini
[options]
db_host = localhost
db_port = 5432
db_user = openspp
db_password = your_password
addons_path = /usr/lib/python3/dist-packages/odoo/addons,/usr/lib/python3/dist-packages/openspp/addons
http_port = 8069
```

## Development

### Prerequisites

- Python 3.10+
- Odoo 17.0
- PostgreSQL 12+
- Git
- Wine (optional, for Windows builds on Linux/macOS)

### Setting Up Development Environment

```bash
# Clone the repository
git clone https://github.com/OpenSPP/openspp-packaging.git
cd openspp-packaging

# Link or copy OpenSPP modules
ln -s /path/to/openspp-modules/* openspp/addons/

# Install development dependencies
pip install -r requirements.txt
pip install -e .
```

### Building from Source

```bash
# Update version in openspp/release.py
vim openspp/release.py

# Build packages
./scripts/build-all.sh

# Test locally
./scripts/test-install.sh
```

### Building Windows Packages on Linux

OpenSPP uses Wine to build Windows installers on Linux, similar to Odoo's approach:

#### Method 1: Using Wine directly
```bash
# Setup Wine environment (one-time)
./setup/windows/setup-wine.sh

# Build Windows installer
python3 setup/package.py --build windows
```

#### Method 2: Using Docker with Wine
```bash
# Build using Docker container with Wine pre-installed
./setup/windows/build-with-docker.sh
```

#### Method 3: GitHub Actions
The CI/CD pipeline automatically builds Windows installers using Wine on Ubuntu runners, eliminating the need for Windows build machines.

## Environment Variables

For publishing packages, set these environment variables:

```bash
# PyPI
export PYPI_USERNAME=your_username
export PYPI_PASSWORD=your_password

# Docker Hub
export DOCKER_USERNAME=your_username
export DOCKER_PASSWORD=your_password

# Package signing
export GPGID=your_gpg_key_id
export GPGPASSPHRASE=your_passphrase
```

## Docker Compose Example

See `setup/docker/docker-compose.yml` for a complete example with PostgreSQL, Redis, and Nginx.

## Support

- Documentation: https://docs.openspp.org
- Issues: https://github.com/OpenSPP/openspp-modules/issues
- Community: https://community.openspp.org

## License

OpenSPP is licensed under LGPL-3. See LICENSE file for details.

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

## Credits

This packaging structure is based on Odoo's packaging approach and adapted for OpenSPP's specific requirements.