#!/bin/bash
# Setup script for OpenSPP packaging environment using uv and pyenv

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}==>${NC} $1"
}

print_error() {
    echo -e "${RED}ERROR:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

# Check for pyenv
print_status "Checking Python environment..."

if command -v pyenv &> /dev/null; then
    print_status "pyenv is installed"
    
    # Check if .python-version exists
    if [ -f ".python-version" ]; then
        PYTHON_VERSION=$(cat .python-version)
        print_status "Using Python version from .python-version: $PYTHON_VERSION"
    else
        # Create .python-version file with recommended version
        PYTHON_VERSION="3.11"
        echo "$PYTHON_VERSION" > .python-version
        print_status "Created .python-version file with Python $PYTHON_VERSION"
    fi
    
    # Check if Python version is installed
    if pyenv versions | grep -q "$PYTHON_VERSION"; then
        print_status "Python $PYTHON_VERSION is installed"
    else
        print_warning "Python $PYTHON_VERSION not found, installing..."
        pyenv install "$PYTHON_VERSION"
    fi
    
    # Set local Python version
    pyenv local "$PYTHON_VERSION"
    print_status "Set local Python to $PYTHON_VERSION"
else
    print_warning "pyenv not found, using system Python"
    print_status "To install pyenv: brew install pyenv"
fi

# Check for uv
print_status "Checking for uv..."

# First check if uv is available globally
if command -v uv &> /dev/null 2>&1; then
    print_status "uv is installed globally"
    UV_CMD="uv"
# Check if uv is in the current Python environment
elif python -m pip show uv &> /dev/null 2>&1; then
    print_status "uv is installed in Python environment, using 'python -m uv'"
    UV_CMD="python -m uv"
# Check if we can run uv through Python
elif python -c "import uv" &> /dev/null 2>&1; then
    print_status "uv module found, using 'python -m uv'"
    UV_CMD="python -m uv"
else
    print_warning "uv not found, installing..."
    
    # Install uv based on OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - prefer standalone installation
        print_status "Installing uv standalone for macOS..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        
        # Add to PATH
        export PATH="$HOME/.cargo/bin:$PATH"
        
        # Also add to shell profile for persistence
        if [ -f "$HOME/.zshrc" ]; then
            echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.zshrc"
            print_status "Added uv to ~/.zshrc"
        elif [ -f "$HOME/.bashrc" ]; then
            echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.bashrc"
            print_status "Added uv to ~/.bashrc"
        fi
        
        UV_CMD="uv"
    else
        # Linux/Unix
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.cargo/bin:$PATH"
        UV_CMD="uv"
    fi
    
    # Verify installation
    if ! command -v uv &> /dev/null 2>&1; then
        print_error "Failed to install uv"
        print_status "Try installing manually: curl -LsSf https://astral.sh/uv/install.sh | sh"
        print_status "Then add to PATH: export PATH=\"\$HOME/.cargo/bin:\$PATH\""
        exit 1
    fi
fi

# Try to get uv version
if [ "$UV_CMD" = "uv" ]; then
    print_status "uv version: $(uv --version 2>/dev/null || echo 'installed')"
else
    print_status "Using uv through Python"
fi

# Create virtual environment with uv
print_status "Setting up virtual environment..."

# Remove old venv if it exists
if [ -d ".venv" ]; then
    print_warning "Removing existing .venv directory..."
    rm -rf .venv
fi

# Create new venv with uv
print_status "Creating virtual environment..."
$UV_CMD venv .venv

# Activate virtual environment
print_status "Activating virtual environment..."
source .venv/bin/activate

# Install dependencies with uv
print_status "Installing dependencies..."

# First, ensure pip and setuptools are up to date
$UV_CMD pip install --upgrade pip setuptools wheel

# Install PyYAML for vendorize.py
$UV_CMD pip install PyYAML

# Install other build dependencies if requirements.txt exists
if [ -f "requirements-dev.txt" ]; then
    print_status "Installing development dependencies..."
    $UV_CMD pip install -r requirements-dev.txt
elif [ -f "requirements.txt" ]; then
    print_status "Installing production dependencies..."
    # Install only essential deps for vendoring
    $UV_CMD pip install PyYAML
fi

# Create pyproject.toml if it doesn't exist
if [ ! -f "pyproject.toml" ]; then
    print_status "Creating pyproject.toml..."
    cat > pyproject.toml << 'EOF'
[project]
name = "openspp-packaging"
version = "17.0.0"
description = "OpenSPP packaging infrastructure"
requires-python = ">=3.10"
dependencies = [
    "PyYAML>=6.0",
]

[build-system]
requires = ["setuptools>=65", "wheel"]
build-backend = "setuptools.build_meta"

[tool.uv]
dev-dependencies = [
    "pytest>=7.0.0",
    "black>=22.0.0",
    "ruff>=0.1.0",
]
EOF
    print_status "Created pyproject.toml"
fi

# Summary
echo ""
print_status "========================================="
print_status "ENVIRONMENT SETUP COMPLETE!"
print_status "========================================="
echo ""
print_status "Python version: $(python --version)"
print_status "Virtual environment: .venv (activated)"
print_status "Package manager: uv"
echo ""
print_status "Next steps:"
echo "  1. The virtual environment is already activated"
echo "  2. Run tests: ./test-local.sh"
echo "  3. Or vendor dependencies: python vendorize.py --lock"
echo ""
print_status "To activate the environment in a new shell:"
echo "  source .venv/bin/activate"
echo ""
print_status "To deactivate:"
echo "  deactivate"