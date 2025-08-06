#!/bin/bash
# Publish OpenSPP packages to various repositories

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "OpenSPP Package Publisher"
echo "=========================================="
echo ""

# Check for required environment variables
check_env() {
    local var_name=$1
    if [ -z "${!var_name}" ]; then
        echo "Error: $var_name is not set"
        return 1
    fi
}

# Publish to PyPI
publish_pypi() {
    echo "Publishing to PyPI..."
    
    if ! command -v twine &> /dev/null; then
        echo "Installing twine..."
        pip install twine
    fi
    
    # Check PyPI credentials
    if ! check_env "PYPI_USERNAME" || ! check_env "PYPI_PASSWORD"; then
        echo "Skipping PyPI publish (credentials not set)"
        return
    fi
    
    # Upload to PyPI
    twine upload \
        --username "$PYPI_USERNAME" \
        --password "$PYPI_PASSWORD" \
        "$PROJECT_ROOT/dist/"*.whl \
        "$PROJECT_ROOT/dist/"*.tar.gz
    
    echo "✓ Published to PyPI"
}

# Publish Docker image
publish_docker() {
    echo "Publishing Docker image..."
    
    if ! command -v docker &> /dev/null; then
        echo "Docker not found, skipping Docker publish"
        return
    fi
    
    # Check Docker Hub credentials
    if ! check_env "DOCKER_USERNAME" || ! check_env "DOCKER_PASSWORD"; then
        echo "Skipping Docker Hub publish (credentials not set)"
        return
    fi
    
    # Login to Docker Hub
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    
    # Push images
    docker push openspp/openspp:latest
    docker push openspp/openspp:17.0
    
    # Logout
    docker logout
    
    echo "✓ Published to Docker Hub"
}

# Publish RPM to repository
publish_rpm() {
    echo "Publishing RPM package..."
    
    RPM_FILE=$(find "$PROJECT_ROOT/dist/" -name "*.rpm" -type f | head -1)
    if [ ! -f "$RPM_FILE" ]; then
        echo "No RPM package found"
        return
    fi
    
    # Check RPM repository credentials
    if ! check_env "RPM_REPO_URL" || ! check_env "RPM_REPO_KEY"; then
        echo "Skipping RPM publish (repository not configured)"
        return
    fi
    
    # Upload to RPM repository
    curl -X POST \
        -H "Authorization: Bearer $RPM_REPO_KEY" \
        -F "file=@$RPM_FILE" \
        "$RPM_REPO_URL/upload"
    
    echo "✓ Published RPM package"
}

# Publish DEB to repository
publish_deb() {
    echo "Publishing DEB package..."
    
    DEB_FILE=$(find "$PROJECT_ROOT/dist/" -name "*.deb" -type f | head -1)
    if [ ! -f "$DEB_FILE" ]; then
        echo "No DEB package found"
        return
    fi
    
    # Check DEB repository credentials
    if ! check_env "DEB_REPO_URL" || ! check_env "DEB_REPO_KEY"; then
        echo "Skipping DEB publish (repository not configured)"
        return
    fi
    
    # Upload to DEB repository (example using dput)
    if command -v dput &> /dev/null; then
        dput ppa:openspp/stable "$DEB_FILE"
        echo "✓ Published DEB package"
    else
        echo "dput not found, cannot publish DEB package"
    fi
}

# Create GitHub release
create_github_release() {
    echo "Creating GitHub release..."
    
    if ! command -v gh &> /dev/null; then
        echo "GitHub CLI not found, skipping GitHub release"
        return
    fi
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Not in a git repository"
        return
    fi
    
    # Get version from release.py
    VERSION=$(python3 -c "exec(open('openspp/release.py').read()); print(version)")
    TAG="v$VERSION"
    
    # Check if tag exists
    if ! git rev-parse "$TAG" >/dev/null 2>&1; then
        echo "Tag $TAG does not exist, creating..."
        git tag -a "$TAG" -m "Release $VERSION"
        git push origin "$TAG"
    fi
    
    # Create release
    gh release create "$TAG" \
        --title "OpenSPP $VERSION" \
        --notes "Release of OpenSPP version $VERSION" \
        "$PROJECT_ROOT/dist/"*
    
    echo "✓ Created GitHub release"
}

# Main execution
cd "$PROJECT_ROOT"

# Parse command line arguments
PUBLISH_PYPI=false
PUBLISH_DOCKER=false
PUBLISH_RPM=false
PUBLISH_DEB=false
PUBLISH_GITHUB=false
PUBLISH_ALL=false

if [ $# -eq 0 ]; then
    PUBLISH_ALL=true
fi

for arg in "$@"; do
    case $arg in
        --pypi)
            PUBLISH_PYPI=true
            ;;
        --docker)
            PUBLISH_DOCKER=true
            ;;
        --rpm)
            PUBLISH_RPM=true
            ;;
        --deb)
            PUBLISH_DEB=true
            ;;
        --github)
            PUBLISH_GITHUB=true
            ;;
        --all)
            PUBLISH_ALL=true
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Usage: $0 [--pypi] [--docker] [--rpm] [--deb] [--github] [--all]"
            exit 1
            ;;
    esac
done

# Publish packages
if [ "$PUBLISH_ALL" = true ] || [ "$PUBLISH_PYPI" = true ]; then
    publish_pypi
fi

if [ "$PUBLISH_ALL" = true ] || [ "$PUBLISH_DOCKER" = true ]; then
    publish_docker
fi

if [ "$PUBLISH_ALL" = true ] || [ "$PUBLISH_RPM" = true ]; then
    publish_rpm
fi

if [ "$PUBLISH_ALL" = true ] || [ "$PUBLISH_DEB" = true ]; then
    publish_deb
fi

if [ "$PUBLISH_ALL" = true ] || [ "$PUBLISH_GITHUB" = true ]; then
    create_github_release
fi

echo ""
echo "=========================================="
echo "Publishing completed!"
echo "=========================================="