#!/bin/bash
# Build all OpenSPP packages

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Parse command line arguments
FETCH_MODULES=true
MODULES_BRANCH="17.0"

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-fetch)
            FETCH_MODULES=false
            shift
            ;;
        --branch)
            MODULES_BRANCH="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --no-fetch     Skip fetching modules from openspp-modules repo"
            echo "  --branch BRANCH    Branch/tag of openspp-modules to use (default: 17.0)"
            echo "  --help         Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "=========================================="
echo "OpenSPP Package Builder"
echo "=========================================="
echo ""

cd "$PROJECT_ROOT"

# Fetch modules if needed
if [ "$FETCH_MODULES" = true ]; then
    echo "Fetching OpenSPP modules..."
    "$SCRIPT_DIR/fetch-modules.sh" --branch "$MODULES_BRANCH"
    echo ""
fi

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf build dist ./*.egg-info

# Build Python packages
echo ""
echo "Building Python packages..."
python3 setup/package.py --build python

# Build platform-specific packages based on OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo ""
    echo "Building Linux packages..."
    
    # Build RPM if on Red Hat-based system
    if command -v rpmbuild &> /dev/null; then
        echo "Building RPM package..."
        python3 setup/package.py --build rpm
    fi
    
    # Build DEB if on Debian-based system
    if command -v dpkg-buildpackage &> /dev/null; then
        echo "Building DEB package..."
        python3 setup/package.py --build deb
    fi
    
    # Build Windows installer with Wine if available
    if command -v wine &> /dev/null; then
        echo ""
        echo "Building Windows installer with Wine..."
        python3 setup/package.py --build windows
    elif command -v docker &> /dev/null; then
        echo ""
        echo "Building Windows installer with Docker/Wine..."
        setup/windows/build-with-docker.sh
    fi
    
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo ""
    echo "Building macOS package..."
    # TODO: Add macOS-specific packaging
    
    # Try to build Windows installer with Wine if available
    if command -v wine &> /dev/null; then
        echo ""
        echo "Building Windows installer with Wine..."
        python3 setup/package.py --build windows
    fi
    
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    echo ""
    echo "Building Windows installer..."
    python3 setup/package.py --build windows
fi

# Build Docker image
if command -v docker &> /dev/null; then
    echo ""
    echo "Building Docker image..."
    python3 setup/package.py --build docker
else
    echo "Docker not found, skipping Docker image build"
fi

# Sign packages if GPG is configured
if [ -n "$GPGID" ]; then
    echo ""
    echo "Signing packages..."
    python3 setup/package.py --sign
fi

echo ""
echo "=========================================="
echo "Build completed successfully!"
echo "Packages are in the dist/ directory"
echo "=========================================="

ls -la dist/