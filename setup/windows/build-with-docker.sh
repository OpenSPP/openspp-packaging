#!/bin/bash
# Build Windows installer using Docker with Wine

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "=========================================="
echo "Building Windows Installer with Docker/Wine"
echo "=========================================="

# Build the Wine Docker image if it doesn't exist
DOCKER_IMAGE="openspp/wine-builder:latest"

echo "Building Wine Docker image..."
docker build -t "$DOCKER_IMAGE" -f "$SCRIPT_DIR/Dockerfile.wine" "$SCRIPT_DIR"

# Run the build in Docker
echo "Building Windows installer in Docker..."
docker run --rm \
    -v "$PROJECT_ROOT:/build" \
    -w /build \
    "$DOCKER_IMAGE" \
    bash -c "
        # Setup environment
        export WINEARCH=win64
        export WINEPREFIX=/wine
        export WINEDEBUG=-all
        
        # Ensure modules are present
        if [ ! -d 'openspp/addons' ] || [ -z \"\$(ls -A openspp/addons)\" ]; then
            echo 'Fetching OpenSPP modules...'
            ./scripts/fetch-modules.sh
        fi
        
        # Build Windows package
        python3 setup/package.py --build windows
    "

echo ""
echo "✅ Windows installer built successfully!"
echo "Check the dist/ directory for the .exe file"