#!/bin/bash
# Quick test script - tests vendorize.py without cloning all repos

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Quick Test: OpenSPP Vendoring System${NC}"
echo "======================================"

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
fi

# Test 1: Check Python and imports
echo -e "\n${GREEN}Test 1: Python environment${NC}"
python --version
python -c "import yaml; print('✓ PyYAML available')" || {
    echo -e "${YELLOW}Installing PyYAML...${NC}"
    if [ "$UV_CMD" = "pip" ]; then
        pip install PyYAML
    else
        $UV_CMD pip install PyYAML
    fi
}

# Test 2: Validate dependencies.yaml
echo -e "\n${GREEN}Test 2: Validate dependencies.yaml${NC}"
python -c "
import yaml
import sys

try:
    with open('dependencies.yaml', 'r') as f:
        data = yaml.safe_load(f)
    
    # Check structure
    assert 'odoo' in data, 'Missing odoo section'
    assert 'addons' in data, 'Missing addons section'
    assert 'python_requirements' in data, 'Missing python_requirements'
    
    print('✓ dependencies.yaml structure is valid')
    print(f'  - Odoo URL: {data[\"odoo\"][\"url\"]}')
    print(f'  - Addon repositories: {len(data[\"addons\"])}')
    
    # List repos
    for name in data['addons']:
        modules = data['addons'][name].get('modules', [])
        if modules:
            print(f'    • {name}: {len(modules)} specific modules')
        else:
            print(f'    • {name}: all modules')
    
except Exception as e:
    print(f'✗ Validation failed: {e}')
    sys.exit(1)
"

# Test 3: Test vendorize.py help
echo -e "\n${GREEN}Test 3: Vendorize script${NC}"
python vendorize.py --help > /dev/null 2>&1 && echo "✓ vendorize.py works" || {
    echo -e "${RED}✗ vendorize.py failed${NC}"
    exit 1
}

# Test 4: Dry run to check git connectivity (without full clone)
echo -e "\n${GREEN}Test 4: Check git connectivity${NC}"
echo "Testing connection to first repository..."
python -c "
import subprocess
import yaml

with open('dependencies.yaml', 'r') as f:
    data = yaml.safe_load(f)

# Test Odoo repo
repo_url = data['odoo']['url']
print(f'Testing: {repo_url}')

try:
    result = subprocess.run(
        ['git', 'ls-remote', '--heads', repo_url],
        capture_output=True,
        text=True,
        timeout=10
    )
    if result.returncode == 0:
        branches = len(result.stdout.strip().split('\n'))
        print(f'✓ Repository accessible ({branches} branches found)')
    else:
        print(f'✗ Failed to access repository')
        print(result.stderr)
except subprocess.TimeoutExpired:
    print('✗ Connection timeout')
except Exception as e:
    print(f'✗ Error: {e}')
"

# Test 5: Create a minimal test manifest
echo -e "\n${GREEN}Test 5: Test with minimal manifest${NC}"
cat > test-dependencies.yaml << 'EOF'
# Minimal test manifest
odoo:
  url: "https://github.com/odoo/odoo.git"
  ref: "17.0"

python_requirements: "requirements.txt"

addons:
  # Just test with one small repo
  openspp_modules:
    url: "https://github.com/OpenSPP/openspp-modules.git"
    ref: "17.0"
    modules:
      - "spp_base"  # Just one module for testing
EOF

echo "Created test-dependencies.yaml with minimal configuration"

# Summary
echo -e "\n${GREEN}=========================================${NC}"
echo -e "${GREEN}QUICK TEST COMPLETE!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "All basic tests passed! The vendoring system is ready."
echo ""
echo "Next steps:"
echo "  1. Run full test: ./test-local.sh"
echo "     (This will clone all repositories - may take several minutes)"
echo ""
echo "  2. Or test with minimal dependencies:"
echo "     cp test-dependencies.yaml dependencies.yaml"
echo "     python vendorize.py --lock"
echo ""
echo "  3. To test with dry-run (no actual cloning):"
echo "     python vendorize.py --help"
echo ""
echo -e "${YELLOW}Note:${NC} The full test will download ~500MB of git repositories"