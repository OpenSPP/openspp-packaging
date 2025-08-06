#!/bin/bash
# Fetch OpenSPP modules from the openspp-modules repository

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MODULES_DIR="$PROJECT_ROOT/openspp/addons"

# Default values
REPO_URL="https://github.com/OpenSPP/openspp-modules.git"
BRANCH="17.0"
CLEAN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --branch|-b)
            BRANCH="$2"
            shift 2
            ;;
        --repo|-r)
            REPO_URL="$2"
            shift 2
            ;;
        --clean|-c)
            CLEAN=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -b, --branch BRANCH    Branch or tag to fetch (default: 17.0)"
            echo "  -r, --repo URL         Repository URL (default: https://github.com/OpenSPP/openspp-modules.git)"
            echo "  -c, --clean            Clean existing modules before fetching"
            echo "  -h, --help             Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "=========================================="
echo "OpenSPP Module Fetcher"
echo "=========================================="
echo "Repository: $REPO_URL"
echo "Branch/Tag: $BRANCH"
echo ""

# Clean existing modules if requested
if [ "$CLEAN" = true ]; then
    echo "Cleaning existing modules..."
    rm -rf "$MODULES_DIR"
fi

# Create modules directory
mkdir -p "$MODULES_DIR"

# Clone or update the repository
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "Fetching modules from repository..."
git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TEMP_DIR/openspp-modules" 2>/dev/null || {
    echo "Failed to clone repository. Trying to fetch specific tag..."
    git clone "$REPO_URL" "$TEMP_DIR/openspp-modules"
    cd "$TEMP_DIR/openspp-modules"
    git checkout "$BRANCH"
}

echo ""
echo "Copying modules..."
cd "$TEMP_DIR/openspp-modules"

# Copy all module directories
MODULE_COUNT=0
for dir in */; do
    # Skip hidden directories and setup directory
    if [[ ! "$dir" =~ ^\. ]] && [[ "$dir" != "setup/" ]]; then
        # Check if it's an Odoo module (has __manifest__.py or __openerp__.py)
        if [[ -f "$dir/__manifest__.py" ]] || [[ -f "$dir/__openerp__.py" ]]; then
            MODULE_NAME=$(basename "$dir")
            echo "  - $MODULE_NAME"
            cp -r "$dir" "$MODULES_DIR/"
            ((MODULE_COUNT++))
        fi
    fi
done

echo ""
echo "✅ Successfully fetched $MODULE_COUNT modules"
echo ""

# Generate module list file
MODULE_LIST_FILE="$PROJECT_ROOT/MODULES.txt"
{
    echo "# OpenSPP Modules"
    echo "# Generated on: $(date)"
    echo "# From: $REPO_URL ($BRANCH)"
    echo ""
    find "$MODULES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
} > "$MODULE_LIST_FILE"

echo "Module list saved to: MODULES.txt"

# Update requirements.txt if needed
if [ -f "$TEMP_DIR/openspp-modules/requirements.txt" ]; then
    echo ""
    echo "Merging requirements..."
    
    # Backup existing requirements
    cp "$PROJECT_ROOT/requirements.txt" "$PROJECT_ROOT/requirements.txt.bak"
    
    # Merge requirements (remove duplicates)
    {
        cat "$PROJECT_ROOT/requirements.txt"
        echo ""
        echo "# Additional requirements from openspp-modules"
        cat "$TEMP_DIR/openspp-modules/requirements.txt"
    } | awk '!seen[$0]++ && NF' > "$PROJECT_ROOT/requirements.txt.tmp"
    
    mv "$PROJECT_ROOT/requirements.txt.tmp" "$PROJECT_ROOT/requirements.txt"
    echo "✅ Requirements merged"
fi

# Check for version compatibility
if [ -f "$TEMP_DIR/openspp-modules/.python-version" ]; then
    MODULES_PYTHON_VERSION=$(cat "$TEMP_DIR/openspp-modules/.python-version")
    echo ""
    echo "ℹ️  Modules require Python: $MODULES_PYTHON_VERSION"
fi

echo ""
echo "=========================================="
echo "Module fetch completed successfully!"
echo "=========================================="