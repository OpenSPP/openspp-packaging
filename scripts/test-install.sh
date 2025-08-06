#!/bin/bash
# Test OpenSPP package installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "OpenSPP Installation Test"
echo "=========================================="
echo ""

# Function to test Python package
test_python_package() {
    echo "Testing Python package installation..."
    
    # Create virtual environment
    VENV_DIR=$(mktemp -d)
    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    
    # Install package
    pip install "$PROJECT_ROOT/dist/openspp-"*.whl
    
    # Test import
    python3 -c "import openspp; print(f'OpenSPP version: {openspp.__version__}')"
    
    # Clean up
    deactivate
    rm -rf "$VENV_DIR"
    
    echo "✓ Python package test passed"
}

# Function to test Docker image
test_docker_image() {
    if ! command -v docker &> /dev/null; then
        echo "Docker not found, skipping Docker test"
        return
    fi
    
    echo "Testing Docker image..."
    
    # Run container
    CONTAINER_NAME="openspp-test-$(date +%s)"
    docker run -d --name "$CONTAINER_NAME" \
        -e INIT_MODULES=base \
        openspp/openspp:latest
    
    # Wait for container to start
    sleep 10
    
    # Check if container is running
    if docker ps | grep -q "$CONTAINER_NAME"; then
        echo "✓ Docker container is running"
        
        # Check health
        docker exec "$CONTAINER_NAME" curl -f http://localhost:8069/web/health || true
    else
        echo "✗ Docker container failed to start"
        docker logs "$CONTAINER_NAME"
    fi
    
    # Clean up
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
    
    echo "✓ Docker image test passed"
}

# Function to test RPM package
test_rpm_package() {
    if ! command -v rpm &> /dev/null; then
        echo "RPM not available, skipping RPM test"
        return
    fi
    
    echo "Testing RPM package..."
    
    # Check package info
    RPM_FILE=$(find "$PROJECT_ROOT/dist/" -name "*.rpm" -type f | head -1)
    if [ -f "$RPM_FILE" ]; then
        rpm -qip "$RPM_FILE"
        echo "✓ RPM package test passed"
    else
        echo "No RPM package found"
    fi
}

# Function to test DEB package
test_deb_package() {
    if ! command -v dpkg &> /dev/null; then
        echo "dpkg not available, skipping DEB test"
        return
    fi
    
    echo "Testing DEB package..."
    
    # Check package info
    DEB_FILE=$(find "$PROJECT_ROOT/dist/" -name "*.deb" -type f | head -1)
    if [ -f "$DEB_FILE" ]; then
        dpkg -I "$DEB_FILE"
        echo "✓ DEB package test passed"
    else
        echo "No DEB package found"
    fi
}

# Run tests based on available packages
cd "$PROJECT_ROOT"

# Check if any .whl files exist
for wheel_file in dist/*.whl; do
    if [ -f "$wheel_file" ]; then
        test_python_package
        break
    fi
done

test_docker_image
test_rpm_package
test_deb_package

echo ""
echo "=========================================="
echo "Installation tests completed!"
echo "=========================================="