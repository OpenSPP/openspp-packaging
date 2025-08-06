# Contributing to OpenSPP Packaging

Thank you for considering contributing to OpenSPP Packaging! This project provides the packaging infrastructure for the OpenSPP (Open Source Social Protection Platform) ecosystem.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Code Style](#code-style)
- [Reporting Issues](#reporting-issues)
- [Community](#community)

## Getting Started

### Prerequisites

- Python 3.10+ (we recommend 3.11)
- Git
- uv (Python package manager)
- pyenv (recommended for Python version management)

### Setup Development Environment

1. **Fork and clone the repository:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/openspp-packaging.git
   cd openspp-packaging
   ```

2. **Set up the environment:**
   ```bash
   # Automated setup
   ./setup-env.sh
   
   # Or manual setup
   pyenv local 3.11
   uv venv .venv
   source .venv/bin/activate
   uv pip install -r requirements-dev.txt
   ```

3. **Verify the setup:**
   ```bash
   python vendorize.py --help
   python -m pytest --version
   ```

## Development Environment

### Project Structure

```
openspp-packaging/
├── dependencies.yaml         # Main dependency manifest
├── dependencies.lock.yaml    # Locked versions (auto-generated)
├── vendorize.py             # Core vendoring script
├── setup.py                 # Python package setup
├── requirements.txt         # Production dependencies
├── requirements-dev.txt     # Development dependencies
├── .github/workflows/       # CI/CD configuration
├── setup/                   # Packaging configurations
│   ├── debian/             # Debian packaging
│   ├── rpm/                # RPM packaging
│   ├── windows/            # Windows installer
│   └── docker/             # Docker configuration
└── scripts/                # Build and utility scripts
```

### Key Components

- **vendorize.py**: Core dependency management script
- **dependencies.yaml**: Source of truth for all dependencies
- **GitHub Actions**: Comprehensive CI/CD pipeline
- **Multi-platform packaging**: Python, DEB, RPM, Windows, Docker

## Making Changes

### Workflow

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes:**
   - Follow the coding standards below
   - Add tests for new functionality
   - Update documentation as needed

3. **Test your changes:**
   ```bash
   # Run quick tests
   ./test-quick.sh
   
   # Run comprehensive tests
   ./test-local.sh
   
   # Test specific functionality
   python -m pytest tests/test_vendorize.py -v
   ```

4. **Commit your changes:**
   ```bash
   git add .
   git commit -m "feat: add new dependency management feature"
   ```

### Dependency Management Changes

When modifying `dependencies.yaml`:

1. **Update the manifest:**
   ```bash
   vim dependencies.yaml
   ```

2. **Generate new lockfile:**
   ```bash
   python vendorize.py --lock
   ```

3. **Test the changes:**
   ```bash
   python vendorize.py --clean
   python vendorize.py --sync
   ```

4. **Commit both files:**
   ```bash
   git add dependencies.yaml dependencies.lock.yaml
   git commit -m "deps: update openspp-modules to v17.0.2"
   ```

## Testing

### Test Categories

1. **Quick Tests** (`./test-quick.sh`):
   - Syntax validation
   - Basic functionality
   - Takes ~2 minutes

2. **Local Tests** (`./test-local.sh`):
   - Full build testing
   - Package creation
   - Takes ~15 minutes

3. **CI Tests** (automatic on PR):
   - Multi-platform builds
   - Security scanning
   - Comprehensive validation

### Writing Tests

- Add tests in the appropriate test files
- Follow the existing test patterns
- Ensure tests are isolated and repeatable
- Mock external dependencies when possible

### Manual Testing

Test the vendoring process:
```bash
# Clean start
python vendorize.py --clean

# Test dependency resolution
python vendorize.py --lock

# Test vendoring
python vendorize.py --sync

# Test package creation
python vendorize.py --tarball 17.0.test
```

## Submitting Changes

### Pull Request Process

1. **Ensure CI passes:**
   - All tests must pass
   - Code must pass linting
   - Security scans must be clean

2. **Create descriptive PR:**
   - Clear title describing the change
   - Detailed description of what and why
   - Reference any related issues

3. **Review process:**
   - Address reviewer feedback promptly
   - Make requested changes in new commits
   - Squash commits before merge if requested

### Commit Message Format

We follow conventional commits:

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (no functional changes)
- `refactor`: Code refactoring
- `test`: Adding or modifying tests
- `ci`: CI/CD changes
- `deps`: Dependency updates

**Examples:**
```bash
feat(vendorize): add caching support for git repositories
fix(ci): correct Docker build context path
docs(readme): update installation instructions
deps(odoo): update to version 17.0.2
```

## Code Style

### Python Code

- **Formatter**: Black (line length: 88)
- **Import sorting**: isort
- **Linting**: flake8, pylint
- **Type hints**: Encouraged for new code

**Run formatting:**
```bash
black .
isort .
flake8 .
```

### Shell Scripts

- **Linting**: shellcheck
- **Style**: Follow existing patterns
- **Error handling**: Use `set -e` and proper error checking

**Run shellcheck:**
```bash
shellcheck scripts/*.sh
```

### YAML Files

- **Indentation**: 2 spaces
- **No trailing spaces**
- **Consistent key ordering**

### Documentation

- **Markdown**: Follow existing style
- **Line length**: 80 characters for text
- **Code blocks**: Specify language for syntax highlighting

## Reporting Issues

### Bug Reports

Use the issue template and include:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, Python version, etc.)
- Relevant logs or error messages

### Feature Requests

- Describe the use case
- Explain why it would be beneficial
- Suggest possible implementation approaches
- Consider backward compatibility

### Security Issues

**Do not open public issues for security vulnerabilities.**

Contact the maintainers privately:
- Email: security@openspp.org
- Follow responsible disclosure practices

## Community

### Communication

- **GitHub Issues**: Bug reports, feature requests
- **GitHub Discussions**: General questions, ideas
- **Community Forum**: https://community.openspp.org
- **Documentation**: https://docs.openspp.org

### Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold this code.

### Getting Help

- Check existing issues and documentation first
- Join community discussions
- Ask specific, detailed questions
- Provide context and examples

## Recognition

Contributors are recognized in:
- GitHub contributors list
- Release notes for significant contributions
- Project documentation

Thank you for contributing to OpenSPP Packaging! Your contributions help improve social protection systems worldwide.