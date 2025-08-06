#!/bin/bash
# Setup Wine environment for building Windows installers on Linux

set -e

echo "Setting up Wine for Windows package building..."

# Install Wine if not present
if ! command -v wine &> /dev/null; then
    echo "Installing Wine..."
    
    # Detect distribution
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        sudo dpkg --add-architecture i386
        sudo apt-get update
        sudo apt-get install -y wine wine32 wine64 winbind
    elif [ -f /etc/redhat-release ]; then
        # RHEL/CentOS/Fedora
        sudo dnf install -y wine wine-core.i686
    else
        echo "Please install Wine manually for your distribution"
        exit 1
    fi
fi

# Initialize Wine prefix
export WINEARCH=win64
export WINEPREFIX=$HOME/.wine

echo "Initializing Wine prefix..."
wineboot -u

# Download and install NSIS
NSIS_VERSION="3.09"
NSIS_URL="https://downloads.sourceforge.net/project/nsis/NSIS%203/${NSIS_VERSION}/nsis-${NSIS_VERSION}-setup.exe"
NSIS_INSTALLER="/tmp/nsis-installer.exe"

if [ ! -f "$WINEPREFIX/drive_c/Program Files (x86)/NSIS/makensis.exe" ] && \
   [ ! -f "$WINEPREFIX/drive_c/Program Files/NSIS/makensis.exe" ]; then
    echo "Downloading NSIS ${NSIS_VERSION}..."
    wget -O "$NSIS_INSTALLER" "$NSIS_URL" || \
        curl -L -o "$NSIS_INSTALLER" "$NSIS_URL"
    
    echo "Installing NSIS in Wine..."
    wine "$NSIS_INSTALLER" /S
    
    # Wait for installation to complete
    sleep 5
    
    rm -f "$NSIS_INSTALLER"
    echo "NSIS installed successfully"
else
    echo "NSIS is already installed in Wine"
fi

# Install Python in Wine (optional, for Python-based installers)
PYTHON_VERSION="3.11.7"
PYTHON_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/python-${PYTHON_VERSION}-amd64.exe"
PYTHON_INSTALLER="/tmp/python-installer.exe"

if [ ! -f "$WINEPREFIX/drive_c/Python311/python.exe" ]; then
    echo "Installing Python ${PYTHON_VERSION} in Wine (optional)..."
    wget -O "$PYTHON_INSTALLER" "$PYTHON_URL" || \
        curl -L -o "$PYTHON_INSTALLER" "$PYTHON_URL"
    
    # Silent install
    wine "$PYTHON_INSTALLER" /quiet InstallAllUsers=1 PrependPath=1 || true
    
    rm -f "$PYTHON_INSTALLER"
fi

# Test NSIS
echo ""
echo "Testing NSIS installation..."
if wine "$WINEPREFIX/drive_c/Program Files (x86)/NSIS/makensis.exe" /VERSION 2>/dev/null; then
    echo "✅ NSIS is working in Wine (x86 location)"
elif wine "$WINEPREFIX/drive_c/Program Files/NSIS/makensis.exe" /VERSION 2>/dev/null; then
    echo "✅ NSIS is working in Wine (x64 location)"
else
    echo "❌ NSIS test failed"
    exit 1
fi

echo ""
echo "Wine setup completed successfully!"
echo "You can now build Windows installers on Linux using:"
echo "  python3 setup/package.py --build windows"