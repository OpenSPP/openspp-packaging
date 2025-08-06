#!/bin/bash
# Local testing script for OpenSPP packaging on macOS

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}==>${NC} $1"
}

print_error() {
    echo -e "${RED}ERROR:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

# Setup environment with uv and pyenv
print_status "Setting up environment..."

# Check if .venv exists, if not run setup
if [ ! -d ".venv" ]; then
    print_warning "Virtual environment not found, running setup..."
    if [ -f "setup-env.sh" ]; then
        ./setup-env.sh
    else
        print_error "setup-env.sh not found. Please run ./setup-env.sh first"
        exit 1
    fi
fi

# Activate virtual environment
print_status "Activating virtual environment..."
source .venv/bin/activate

# Verify we're in the venv
if [ -z "$VIRTUAL_ENV" ]; then
    print_error "Failed to activate virtual environment"
    exit 1
fi

print_status "Using Python from: $(which python)"
print_status "Python version: $(python --version)"
print_status "Git version: $(git --version)"

# Detect uv command
if command -v uv &> /dev/null 2>&1; then
    UV_CMD="uv"
elif python -m pip show uv &> /dev/null 2>&1; then
    UV_CMD="python -m uv"
else
    UV_CMD="pip"  # Fallback to regular pip
fi

# Check for PyYAML in the venv
print_status "Checking for PyYAML..."
if ! python -c "import yaml" 2>/dev/null; then
    print_warning "PyYAML not found, installing..."
    if [ "$UV_CMD" = "pip" ]; then
        pip install PyYAML
    else
        $UV_CMD pip install PyYAML
    fi
else
    print_status "PyYAML is installed"
fi

# Clean previous test artifacts
print_status "Cleaning previous test artifacts..."
rm -rf vendor/ .tmp_vendor_clones/ openspp-*.tar.gz dependencies.lock.yaml

# Test 1: Vendoring with lock
print_status "Test 1: Creating lockfile and vendoring dependencies"
print_status "This will clone multiple repositories - it may take a few minutes..."

python vendorize.py --lock --verbose

if [ -f "dependencies.lock.yaml" ]; then
    print_status "✓ Lockfile created successfully"
else
    print_error "✗ Lockfile creation failed"
    exit 1
fi

if [ -d "vendor" ]; then
    print_status "✓ Vendor directory created"
    
    # Count vendored modules
    ODOO_EXISTS=$([ -d "vendor/odoo" ] && echo "yes" || echo "no")
    ADDON_COUNT=$(find vendor/addons -type d -name "__manifest__.py" -o -name "__openerp__.py" | wc -l | tr -d ' ')
    
    print_status "Vendoring summary:"
    echo "  - Odoo core: $ODOO_EXISTS"
    echo "  - Addon modules found: $ADDON_COUNT"
    
    # List addon repositories
    print_status "Addon repositories vendored:"
    for dir in vendor/addons/*/; do
        if [ -d "$dir" ]; then
            repo_name=$(basename "$dir")
            module_count=$(find "$dir" -maxdepth 1 -type d ! -path "$dir" | wc -l | tr -d ' ')
            echo "  - $repo_name: $module_count modules"
        fi
    done
else
    print_error "✗ Vendor directory not created"
    exit 1
fi

# Test 2: Create source tarball
print_status "Test 2: Creating source tarball"
VERSION="17.0.test-$(date +%Y%m%d)"
python vendorize.py --tarball "$VERSION"

TARBALL="openspp-${VERSION}-source.tar.gz"
if [ -f "$TARBALL" ]; then
    SIZE=$(du -h "$TARBALL" | cut -f1)
    print_status "✓ Source tarball created: $TARBALL (size: $SIZE)"
    
    # List contents summary
    print_status "Tarball contents (first 20 files):"
    tar -tzf "$TARBALL" | head -20
else
    print_error "✗ Source tarball creation failed"
    exit 1
fi

# Test 3: Clean and sync from lockfile
print_status "Test 3: Testing sync from lockfile"
print_status "Removing vendor directory..."
rm -rf vendor/

print_status "Syncing from lockfile..."
python vendorize.py --sync

if [ -d "vendor" ]; then
    print_status "✓ Successfully synced from lockfile"
else
    print_error "✗ Sync from lockfile failed"
    exit 1
fi

# Test 4: Verify Python package can be built (optional)
print_status "Test 4: Testing Python package build (optional)"
print_status "Installing Python build tools..."
if [ "$UV_CMD" = "pip" ]; then
    pip install --quiet build wheel setuptools 2>/dev/null || true
else
    $UV_CMD pip install --quiet build wheel setuptools 2>/dev/null || true
fi

if python -c "import build" 2>/dev/null; then
    print_status "Building Python package..."
    python -m build --wheel --outdir test-dist/ 2>/dev/null || {
        print_warning "Python package build failed (this is expected if setup.py is not complete)"
    }
    
    if [ -d "test-dist" ] && [ "$(ls -A test-dist)" ]; then
        print_status "✓ Python wheel created in test-dist/"
        ls -la test-dist/
    fi
else
    print_warning "Python build tools not available, skipping Python package test"
fi

# Summary
echo ""
print_status "========================================="
print_status "LOCAL TESTING COMPLETE!"
print_status "========================================="
echo ""
print_status "Summary:"
echo "  ✓ Vendoring system works"
echo "  ✓ Lockfile generation works"
echo "  ✓ Source tarball creation works"
echo "  ✓ Sync from lockfile works"
echo ""
print_status "Next steps:"
echo "  1. Review the vendored modules in vendor/addons/"
echo "  2. Check dependencies.lock.yaml for resolved commits"
echo "  3. Extract and inspect the source tarball if needed"
echo "  4. Commit dependencies.yaml and dependencies.lock.yaml"
echo "  5. Push to GitHub to trigger CI/CD builds"
echo ""
print_status "To clean up test artifacts:"
echo "  rm -rf vendor/ .tmp_vendor_clones/ openspp-*.tar.gz test-dist/"