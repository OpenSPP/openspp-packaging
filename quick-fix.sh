#!/bin/bash
# Quick fix for uv PATH issue on macOS with pyenv

set -e

echo "Quick fix for uv PATH issue..."

# Add cargo bin to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
    echo "Added $HOME/.cargo/bin to PATH"
fi

# Add to shell profile
if [ -f "$HOME/.zshrc" ] && ! grep -q "cargo/bin" "$HOME/.zshrc"; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.zshrc"
    echo "Added to ~/.zshrc for future sessions"
fi

# Test uv
if command -v uv &> /dev/null; then
    echo "✅ uv is now available: $(uv --version)"
    echo ""
    echo "Now you can run:"
    echo "  ./setup-env.sh"
else
    echo "❌ uv still not found, installing it..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
    echo ""
    if command -v uv &> /dev/null; then
        echo "✅ uv installed: $(uv --version)"
        echo "Run: ./setup-env.sh"
    else
        echo "❌ Installation failed. Please install manually:"
        echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
        echo "  export PATH=\"\$HOME/.cargo/bin:\$PATH\""
    fi
fi