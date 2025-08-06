#!/bin/bash
# Minimal vendoring test - uses a small subset of dependencies for quick testing

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Running minimal vendoring test...${NC}"
echo "This will only fetch a small subset of dependencies for testing"
echo ""

# Setup environment if needed
if [ ! -d ".venv" ]; then
    echo -e "${YELLOW}Setting up environment...${NC}"
    if [ -f "setup-env.sh" ]; then
        ./setup-env.sh
    else
        echo -e "${RED}setup-env.sh not found${NC}"
        exit 1
    fi
fi

# Activate virtual environment
source .venv/bin/activate

# Detect uv command
if command -v uv &> /dev/null 2>&1; then
    UV_CMD="uv"
elif python -m pip show uv &> /dev/null 2>&1; then
    UV_CMD="python -m uv"
else
    UV_CMD="pip"  # Fallback to regular pip
    echo -e "${YELLOW}Using pip instead of uv${NC}"
fi

# Backup original dependencies.yaml
cp dependencies.yaml dependencies.yaml.backup

# Create minimal dependencies file
cat > dependencies.yaml << 'EOF'
# Minimal dependencies for testing
odoo:
  url: "https://github.com/odoo/odoo.git"
  ref: "17.0"

python_requirements: "requirements.txt"

addons:
  # Just one small repo for testing
  oca_server_tools:
    url: "https://github.com/OCA/server-tools.git"
    ref: "17.0"
    modules:
      - "base_multi_image"
EOF

echo -e "${GREEN}Step 1: Creating lockfile and vendoring...${NC}"
python vendorize.py --lock

echo -e "\n${GREEN}Step 2: Checking results...${NC}"
if [ -f "dependencies.lock.yaml" ]; then
    echo "✓ Lockfile created"
    echo "Contents:"
    cat dependencies.lock.yaml
fi

echo ""
if [ -d "vendor" ]; then
    echo "✓ Vendor directory created"
    echo "Structure:"
    find vendor -type d -maxdepth 3 | head -20
fi

echo -e "\n${GREEN}Step 3: Creating test tarball...${NC}"
python vendorize.py --tarball test-build

if [ -f "openspp-test-build-source.tar.gz" ]; then
    SIZE=$(du -h openspp-test-build-source.tar.gz | cut -f1)
    echo "✓ Tarball created: openspp-test-build-source.tar.gz ($SIZE)"
fi

# Restore original dependencies.yaml
echo -e "\n${GREEN}Restoring original dependencies.yaml...${NC}"
mv dependencies.yaml.backup dependencies.yaml

echo -e "\n${GREEN}Test complete!${NC}"
echo "To run full vendoring with all dependencies:"
echo "  python vendorize.py --lock"
echo ""
echo "To clean up test artifacts:"
echo "  rm -rf vendor/ openspp-test-build-source.tar.gz dependencies.lock.yaml"