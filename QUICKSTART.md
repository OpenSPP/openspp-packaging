# OpenSPP Packaging - Quick Start Guide

## 🚀 Getting Started

### Prerequisites

- Git
- Python 3.10+
- Docker (optional, for Docker builds)
- GitHub CLI (`gh`) for repository operations
- Wine (optional, for Windows builds on Linux/macOS)

### Initial Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/OpenSPP/openspp-packaging.git
   cd openspp-packaging
   ```

2. **Fetch OpenSPP modules:**
   ```bash
   ./scripts/fetch-modules.sh
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

## 📦 Building Packages

### Build All Packages
```bash
./scripts/build-all.sh
```

### Build Specific Package Types
```bash
# Python package only
python3 setup/package.py --build python

# Docker image only
python3 setup/package.py --build docker

# RPM package only
python3 setup/package.py --build rpm

# Debian package only
python3 setup/package.py --build deb

# Windows package (works on Linux with Wine!)
python3 setup/package.py --build windows
```

### Building Windows Packages on Linux/macOS

```bash
# Quick setup Wine for Windows builds
./setup/windows/setup-wine.sh

# Or use Docker (no setup needed)
./setup/windows/build-with-docker.sh
```

## 🚢 GitHub Actions Workflows

### Weekly Releases (Automated)

- **Schedule**: Every Monday at 2 AM UTC
- **Trigger manually**: 
  ```bash
  gh workflow run weekly-release.yml
  ```

### Tag Releases

- **Automatic**: Triggers when pushing a tag starting with `v`
  ```bash
  git tag v17.0.2
  git push origin v17.0.2
  ```

- **Manual trigger**:
  ```bash
  gh workflow run tag-release.yml -f version=17.0.2
  ```

### Manual Release

```bash
# Full release
gh workflow run manual-release.yml \
  -f version=17.0.2 \
  -f modules_ref=17.0 \
  -f release_type=stable \
  -f publish_targets=pypi,docker,github

# Dry run (build only)
gh workflow run manual-release.yml \
  -f version=17.0.2 \
  -f modules_ref=17.0 \
  -f release_type=beta \
  -f dry_run=true
```

## 🔑 Required Secrets

> **Note**: External publishing is currently disabled. Packages are only published to GitHub Releases.

When ready to enable external publishing, configure these secrets:

1. **PyPI Publishing:** (Currently disabled)
   - `PYPI_API_TOKEN` - Get from https://pypi.org/manage/account/token/

2. **Docker Hub Publishing:** (Currently disabled)
   - `DOCKER_USERNAME` - Your Docker Hub username
   - `DOCKER_PASSWORD` - Docker Hub access token

See [.github/SECRETS.md](.github/SECRETS.md) for instructions on enabling external publishing.

## 📝 Common Tasks

### Update modules from specific branch
```bash
./scripts/fetch-modules.sh --branch 17.0-dev
```

### Test package installation
```bash
./scripts/test-install.sh
```

### Create a new release
1. Update version in `openspp/release.py`
2. Commit changes
3. Create and push tag:
   ```bash
   git tag v17.0.2
   git push origin v17.0.2
   ```

### Check workflow status
```bash
# List recent workflow runs
gh run list

# View specific workflow run
gh run view

# Watch workflow in real-time
gh run watch
```

## 🐳 Docker Quick Start

### Build locally
```bash
docker build -f setup/docker/Dockerfile -t openspp/openspp:local .
```

### Run from GitHub Release
```bash
# Download Docker image
gh release download v17.0.1 --pattern "openspp-docker-*.tar"

# Load image
docker load -i openspp-docker-17.0.1.tar

# Run container
docker run -d -p 8069:8069 openspp/openspp:17.0
```

### Run with docker-compose
```bash
cd setup/docker
docker-compose up -d
```

Access OpenSPP at http://localhost:8069

## 📊 Monitoring Releases

### Check latest release
```bash
gh release view
```

### List all releases
```bash
gh release list
```

### Download release assets
```bash
gh release download v17.0.2
```

## 🆘 Troubleshooting

### Modules not found
```bash
# Re-fetch modules
./scripts/fetch-modules.sh --clean
```

### Build fails
```bash
# Clean build artifacts
rm -rf build/ dist/ *.egg-info
./scripts/build-all.sh
```

### Workflow fails
```bash
# Check workflow logs
gh run view --log-failed

# Re-run failed jobs
gh run rerun --failed
```

## 📚 Documentation

- [Packaging Specification](specs.md)
- [GitHub Secrets Setup](.github/SECRETS.md)
- [Full README](README.md)
- [OpenSPP Documentation](https://docs.openspp.org)

## 💡 Tips

1. **Always test locally first:**
   ```bash
   ./scripts/build-all.sh --no-fetch
   ./scripts/test-install.sh
   ```

2. **Use dry run for manual releases:**
   ```bash
   gh workflow run manual-release.yml -f dry_run=true
   ```

3. **Monitor weekly releases:**
   - Check GitHub Actions tab every Monday
   - Review automated issues for failures

4. **Version naming:**
   - Stable: `17.0.2`
   - Beta: `17.0.2-beta1`
   - RC: `17.0.2-rc1`
   - Weekly: `17.0.2.20240115`