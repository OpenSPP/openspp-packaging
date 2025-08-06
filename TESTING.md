# Testing OpenSPP Packaging Locally

## Environment Setup (Required First)

We use `uv` for virtual environment management and `pyenv` for Python version control:

```bash
# First-time setup - installs uv, sets Python version, creates venv
./setup-env.sh

# This will:
# - Check/install pyenv and set Python 3.11
# - Install uv if not present
# - Create a .venv virtual environment
# - Install PyYAML and other dependencies
```

After setup, the virtual environment will be activated automatically. For new terminal sessions:

```bash
source .venv/bin/activate
```

## Quick Start

We provide three levels of testing, from quick validation to full integration. All test scripts automatically use the virtual environment:

### 1. Quick Test (30 seconds)
Tests the basic setup without downloading repositories:

```bash
./test-quick.sh
```

This verifies:
- Python environment and PyYAML
- dependencies.yaml structure
- Git connectivity
- vendorize.py functionality

### 2. Minimal Test (2-3 minutes)
Tests with a small subset of dependencies:

```bash
./run-minimal-test.sh
```

This will:
- Vendor only Odoo and one small addon repository
- Create a lockfile
- Generate a test tarball
- Show the vendored structure

### 3. Full Test (10-15 minutes)
Complete test with all dependencies:

```bash
./test-local.sh
```

This performs:
- Full vendoring of all repositories
- Lockfile generation
- Source tarball creation
- Sync from lockfile test
- Python package build test

## Manual Testing

### Step 1: Setup Environment

```bash
# Run setup if not already done
./setup-env.sh

# Or manually:
# 1. Set Python version with pyenv
pyenv local 3.11

# 2. Create virtual environment with uv
uv venv .venv

# 3. Activate it
source .venv/bin/activate

# 4. Install dependencies
uv pip install PyYAML
```

### Step 2: Test Vendoring

```bash
# Ensure venv is activated
source .venv/bin/activate

# Create lockfile and vendor all dependencies
python vendorize.py --lock

# Check results
ls -la vendor/
cat dependencies.lock.yaml
```

### Step 3: Create Source Tarball

```bash
# Create a tarball for distribution
python vendorize.py --tarball 17.0.test

# Check the tarball
tar -tzf openspp-17.0.test-source.tar.gz | head -20
```

### Step 4: Test Sync from Lockfile

```bash
# Remove vendor directory
rm -rf vendor/

# Sync from lockfile
python vendorize.py --sync

# Vendor directory should be recreated
ls -la vendor/
```

## Testing Specific Components

### Test Dependency Resolution

```bash
# Check if a specific repository is accessible
git ls-remote https://github.com/OpenSPP/openspp-modules.git 17.0

# Test ref resolution (ensure venv is activated first)
python -c "
from vendorize import resolve_ref
sha = resolve_ref('https://github.com/odoo/odoo.git', '17.0')
print(f'Resolved to: {sha}')
"
```

### Test Module Discovery

```bash
# After vendoring, check discovered modules
find vendor/addons -name "__manifest__.py" -o -name "__openerp__.py" | wc -l
```

### Test Selective Module Inclusion

Edit `dependencies.yaml` to test selective inclusion:

```yaml
addons:
  oca_server_tools:
    url: "https://github.com/OCA/server-tools.git"
    ref: "17.0"
    modules:
      - "base_multi_image"
      - "base_export_async"
```

Then vendor and verify only specified modules are included:

```bash
python vendorize.py --lock
ls vendor/addons/oca_server_tools/
```

## Troubleshooting

### PyYAML Not Found

```bash
# Make sure venv is activated first
source .venv/bin/activate

# Install with uv
uv pip install PyYAML
```

### Virtual Environment Issues

```bash
# If venv is corrupted, recreate it
rm -rf .venv
./setup-env.sh

# Or manually with uv
uv venv .venv
source .venv/bin/activate
uv pip install PyYAML
```

### Git Authentication Issues

If you get authentication errors for private repos:

```bash
# Configure git credentials
git config --global credential.helper osxkeychain

# Or use SSH URLs in dependencies.yaml
url: "git@github.com:OpenSPP/private-repo.git"
```

### Network Timeouts

The vendorize script retries 3 times by default. For slow connections:

```bash
# Edit vendorize.py and increase retries/delay
def run_cmd(..., retries=5, delay=10):
```

### Large Repository Issues

For very large repositories, the initial clone might timeout:

```bash
# Increase git timeout
git config --global http.postBuffer 524288000
git config --global http.timeout 600
```

## Clean Up

Remove all test artifacts:

```bash
# Remove vendored files
rm -rf vendor/ .tmp_vendor_clones/

# Remove build artifacts
rm -rf openspp-*.tar.gz dependencies.lock.yaml

# Remove test builds
rm -rf dist/ build/ *.egg-info test-dist/

# Remove test files
rm -f test-dependencies.yaml test-minimal.yaml
```

## Expected Output

### Successful Quick Test
```
✓ PyYAML available
✓ dependencies.yaml structure is valid
✓ vendorize.py works
✓ Repository accessible (87 branches found)
```

### Successful Vendoring
```
Creating lockfile with resolved commits...
Resolved '17.0' to abc123...
Syncing dependencies from lockfile...
Vendoring complete!
Vendored Odoo core and 250 addon modules
```

### Successful Tarball Creation
```
Creating source tarball: openspp-17.0.test-source.tar.gz
Source tarball created: openspp-17.0.test-source.tar.gz (245.3 MB)
```

## Performance Expectations

On a typical macOS system with good internet:

- **Quick test**: < 30 seconds
- **Minimal vendoring**: 2-3 minutes
- **Full vendoring**: 10-15 minutes (first time)
- **Sync from lockfile**: 5-10 minutes
- **Tarball creation**: < 1 minute

The first vendoring is slowest as it clones all repositories. Subsequent runs can use git cache.

## CI/CD Simulation

To simulate what happens in GitHub Actions:

```bash
# 0. Activate virtual environment
source .venv/bin/activate

# 1. Clean start
rm -rf vendor/ dependencies.lock.yaml

# 2. Run vendoring
python vendorize.py --lock

# 3. Create tarball (simulates release)
VERSION="17.0.$(date +%Y%m%d)"
python vendorize.py --tarball $VERSION

# 4. This tarball would be used by all parallel build jobs
echo "Source tarball ready: openspp-${VERSION}-source.tar.gz"
```

## Next Steps

After successful local testing:

1. **Commit the changes**:
   ```bash
   git add dependencies.yaml dependencies.lock.yaml
   git add vendorize.py *.sh *.md
   git commit -m "feat: Implement vendored source tarball packaging"
   ```

2. **Push to GitHub**:
   ```bash
   git push origin main
   ```

3. **Create a test release**:
   ```bash
   git tag v17.0.test
   git push origin v17.0.test
   ```

This will trigger the GitHub Actions workflow to build all package formats.