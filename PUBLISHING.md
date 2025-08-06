# OpenSPP Publishing Strategy

## Current Status

OpenSPP packages are currently published **only to GitHub Releases**. External publishing to PyPI and Docker Hub is disabled by default to allow for initial testing and validation within the GitHub ecosystem.

## Available Packages

Each release includes the following artifacts:

- **Python Package**: `openspp-{version}-py3-none-any.whl` and `.tar.gz`
- **Debian Package**: `openspp_{version}_all.deb`
- **RPM Package**: `openspp-{version}-1.noarch.rpm`
- **Windows Installer**: `openspp-{version}-setup.exe`
- **Docker Image**: `openspp-docker-{version}.tar`

## Installation from GitHub Releases

### Download Latest Release

```bash
# Using GitHub CLI
gh release download v17.0.1

# Using wget
wget https://github.com/OpenSPP/openspp-packaging/releases/download/v17.0.1/openspp-17.0.1-py3-none-any.whl

# Using curl
curl -LO https://github.com/OpenSPP/openspp-packaging/releases/download/v17.0.1/openspp-17.0.1-py3-none-any.whl
```

### Install Downloaded Packages

#### Python
```bash
pip install openspp-17.0.1-py3-none-any.whl
```

#### Debian/Ubuntu
```bash
sudo dpkg -i openspp_17.0.1_all.deb
sudo apt-get install -f  # Install dependencies
```

#### Red Hat/Fedora
```bash
sudo rpm -i openspp-17.0.1-1.noarch.rpm
```

#### Windows
Double-click `openspp-17.0.1-setup.exe` and follow the installer.

#### Docker
```bash
docker load -i openspp-docker-17.0.1.tar
docker run -d -p 8069:8069 openspp/openspp:17.0
```

## Release Schedule

- **Weekly Releases**: Every Monday at 2 AM UTC (if changes detected)
- **Tag Releases**: On-demand when pushing version tags
- **Manual Releases**: Triggered via GitHub Actions UI

## Future Publishing Plans

When the project is ready for broader distribution:

### Phase 1: Enable PyPI (Target: Q2 2024)
- Register `openspp` package name on PyPI
- Configure PyPI API token
- Enable in workflows: `publish_pypi: true`

### Phase 2: Enable Docker Hub (Target: Q2 2024)
- Create `openspp` organization on Docker Hub
- Configure Docker Hub credentials
- Enable in workflows: `publish_docker: true`

### Phase 3: Package Repositories (Target: Q3 2024)
- Set up APT repository for Debian/Ubuntu
- Set up YUM repository for RHEL/Fedora
- Configure automatic repository updates

## Enabling External Publishing

To enable external publishing now:

1. **Configure Secrets** in GitHub repository settings:
   - `PYPI_API_TOKEN`
   - `DOCKER_USERNAME`
   - `DOCKER_PASSWORD`

2. **Update Workflows**:
   
   Edit `.github/workflows/weekly-release.yml`:
   ```yaml
   publish_pypi: true
   publish_docker: true
   ```
   
   Edit `.github/workflows/tag-release.yml`:
   ```yaml
   publish_pypi: true
   publish_docker: true
   ```

3. **Test with Manual Release**:
   ```bash
   gh workflow run manual-release.yml \
     -f version=17.0.1-test \
     -f publish_targets=pypi,docker,github \
     -f dry_run=false
   ```

## Security Considerations

- All packages are built in GitHub Actions with full audit trail
- Releases are signed with GitHub's attestation
- Package integrity can be verified via checksums
- Docker images include security scanning via Trivy

## Support

For issues with package installation or distribution:
- GitHub Issues: https://github.com/OpenSPP/openspp-packaging/issues
- Documentation: https://docs.openspp.org/installation