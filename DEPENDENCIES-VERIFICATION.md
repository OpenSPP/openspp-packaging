# OpenSPP Dependencies Verification

This document verifies that our `dependencies.yaml` matches the configuration from openspp-docker repository.

## Verification Date
- Checked against: https://github.com/OpenSPP/openspp-docker/tree/17.0
- Date: 2024

## Repository Comparison

| Repository | openspp-docker (repos.yaml) | Our Config (dependencies.yaml) | Status |
|------------|----------------------------|--------------------------------|---------|
| **Odoo** | https://github.com/odoo/odoo.git @ 17.0 | ✅ Same | ✅ Match |
| **openspp_modules** | https://github.com/openspp/openspp-modules.git @ openspp-17.0.1.2.1 | ✅ Updated to match | ✅ Match |
| **openg2p_registry** | https://github.com/OpenSPP/openg2p-registry.git @ 17.0-develop-openspp | ✅ Same | ✅ Match |
| **openg2p_program** | https://github.com/OpenSPP/openg2p-program.git @ 17.0-develop-openspp | ✅ Same | ✅ Match |
| **openg2p_auth** | https://github.com/OpenSPP/openg2p-auth.git @ 17.0-develop-openspp | ✅ Same | ✅ Match |
| **openg2p_rest_framework** | https://github.com/OpenSPP/openg2p-rest-framework.git @ 17.0-openspp | ✅ Same | ✅ Match |
| **muk_addons** | https://github.com/OpenSPP/mukit-modules.git @ 17.0-openspp | ✅ Same | ✅ Match |
| **server-tools** | https://github.com/OCA/server-tools.git @ 17.0 | ✅ Same | ✅ Match |
| **server-ux** | https://github.com/OCA/server-ux.git @ 17.0 | ✅ Same | ✅ Match |
| **queue** | https://github.com/OCA/queue.git @ 17.0 | ✅ Same | ✅ Match |
| **server-backend** | https://github.com/OCA/server-backend.git @ 17.0 | ✅ Same | ✅ Match |
| **web-api** | https://github.com/OCA/web-api.git @ 17.0 | ✅ Same | ✅ Match |

## Module Selection Comparison

| Repository | openspp-docker (addons.yaml) | Our Config (dependencies.yaml) | Status |
|------------|------------------------------|--------------------------------|---------|
| **openspp_modules** | All modules ("*") | All modules | ✅ Match |
| **openg2p_registry** | All modules ("*") | All modules | ✅ Match |
| **openg2p_program** | All modules ("*") | All modules | ✅ Match |
| **openg2p_rest_framework** | fastapi, extendable, extendable_fastapi | Same 3 modules | ✅ Match |
| **muk_addons** | All modules ("*") | All modules | ✅ Match |
| **server-tools** | base_multi_image | base_multi_image | ✅ Match |
| **server-ux** | mass_editing | mass_editing | ✅ Match |
| **queue** | queue_job | queue_job | ✅ Match |
| **server-backend** | All modules ("*") | All modules | ✅ Match |
| **web-api** | endpoint_route_handler | endpoint_route_handler | ✅ Match |

## Changes Made

✅ **Updated**: `openspp_modules` branch from `17.0` to `openspp-17.0.1.2.1` to match openspp-docker

## Summary

✅ **All dependencies are now correctly aligned with openspp-docker configuration**

The `dependencies.yaml` file now exactly matches the openspp-docker repository configuration for:
- All repository URLs
- All branches/refs
- All module selections

## Testing After Update

To test with the updated configuration:

```bash
# Clean cache to ensure fresh clone of openspp_modules with new branch
python3 vendorize.py --clean-cache

# Re-vendor with updated dependencies
python3 vendorize.py --lock

# Verify the openspp_modules branch
cd vendor/addons/openspp_modules
git log --oneline -1  # Should show commit from openspp-17.0.1.2.1 branch
```