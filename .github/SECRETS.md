# GitHub Actions Secrets Configuration

This document describes the secrets that need to be configured for the GitHub Actions workflows to work properly.

> **Note**: External publishing (PyPI, Docker Hub) is currently **disabled by default** in all workflows. Packages are only published to GitHub Releases. When you're ready to enable external publishing, update the workflow files and configure the secrets below.

## Required Secrets (Currently Optional)

### PyPI Publishing

- **`PYPI_API_TOKEN`** - API token for publishing packages to PyPI
  - How to obtain:
    1. Go to https://pypi.org/manage/account/token/
    2. Create a new API token with "Upload packages" scope
    3. Copy the token (starts with `pypi-`)
    4. Add as repository secret

### Docker Hub Publishing

- **`DOCKER_USERNAME`** - Docker Hub username
  - Your Docker Hub account username

- **`DOCKER_PASSWORD`** - Docker Hub password or access token
  - How to obtain:
    1. Go to https://hub.docker.com/settings/security
    2. Create a new access token
    3. Copy the token
    4. Add as repository secret

## Optional Secrets

### Package Signing (if needed)

- **`GPG_PRIVATE_KEY`** - GPG private key for signing packages
- **`GPG_PASSPHRASE`** - Passphrase for the GPG key

## Setting Secrets

To add these secrets to your repository:

1. Go to your repository on GitHub
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add each secret with the exact name listed above

## Workflow Permissions

Ensure your repository has the following permissions enabled:

1. Go to Settings → Actions → General
2. Under "Workflow permissions", select:
   - "Read and write permissions"
   - "Allow GitHub Actions to create and approve pull requests"

## Testing the Configuration

After setting up the secrets, you can test the configuration:

1. **Test Weekly Release (without publishing):**
   ```bash
   gh workflow run weekly-release.yml -f skip_publish=true
   ```

2. **Test Tag Release:**
   ```bash
   gh workflow run tag-release.yml -f version=17.0.0-test1
   ```

## Enabling External Publishing

When you're ready to publish to PyPI and Docker Hub, follow these steps:

### 1. Configure Secrets
Add the required secrets as described above.

### 2. Enable in Workflows

#### For Weekly Releases
Edit `.github/workflows/weekly-release.yml`:
```yaml
publish_pypi: true  # Change from false
publish_docker: true  # Change from false
```

#### For Tag Releases
Edit `.github/workflows/tag-release.yml`:
```yaml
publish_pypi: true  # Change from false
publish_docker: true  # Change from false
```

#### For Manual Releases
No changes needed - you can specify targets when triggering:
```bash
gh workflow run manual-release.yml \
  -f publish_targets=pypi,docker,github
```

## Troubleshooting

### PyPI Upload Fails
- Ensure the API token has the correct scope
- Check if the package name is available on PyPI
- Verify the token hasn't expired

### Docker Push Fails
- Ensure the Docker Hub account has access to the `openspp` organization
- Check if 2FA is enabled and use an access token instead of password
- Verify the repository exists on Docker Hub

### GitHub Release Creation Fails
- Ensure the workflow has write permissions for contents
- Check if the tag already exists
- Verify the GITHUB_TOKEN has the correct permissions