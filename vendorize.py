#!/usr/bin/env python3
"""
OpenSPP Dependency Vendoring Script

This script manages the vendoring of all OpenSPP dependencies from the
dependencies.yaml manifest file. It creates a lockfile with resolved commit
SHAs and syncs all dependencies to a local vendor directory.

Usage:
    python vendorize.py --lock    # Resolve refs and update lockfile
    python vendorize.py --sync    # Sync from existing lockfile
    python vendorize.py --clean   # Remove vendor directory
"""

import argparse
import logging
import shutil
import subprocess
import sys
import tarfile
import time
import yaml
from pathlib import Path
from typing import Dict, List, Optional, Any

# Constants
VENDOR_DIR = Path("./vendor")
ADDONS_DEST_DIR = VENDOR_DIR / "addons"
ODOO_DEST_DIR = VENDOR_DIR / "odoo"
TMP_DIR = Path("./.tmp_vendor_clones")
MANIFEST_FILE = Path("dependencies.yaml")
LOCKFILE = Path("dependencies.lock.yaml")

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class VendorizeError(Exception):
    """Custom exception for vendorize errors"""

    pass


def run_cmd(
    cmd: List[str], cwd: Optional[Path] = None, retries: int = 3, delay: int = 5
) -> str:
    """
    Run a command with retries for network operations.

    Args:
        cmd: Command and arguments as a list
        cwd: Working directory for the command
        retries: Number of retry attempts
        delay: Delay between retries in seconds

    Returns:
        stdout from the command

    Raises:
        VendorizeError: If command fails after all retries
    """
    for attempt in range(retries):
        try:
            logger.debug(f"Running command: {' '.join(cmd)}")
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=True,
                cwd=cwd,
                encoding="utf-8",
            )
            return result.stdout.strip()
        except subprocess.CalledProcessError as e:
            logger.warning(
                f"Command '{' '.join(cmd)}' failed. Attempt {attempt + 1}/{retries}"
            )
            logger.debug(f"Stderr: {e.stderr}")
            if attempt == retries - 1:
                raise VendorizeError(
                    f"Command failed after {retries} attempts: {e.stderr}"
                )
            time.sleep(delay)


def resolve_ref(repo_url: str, ref: str) -> str:
    """
    Resolve a git ref (branch/tag) to a full commit SHA.

    Args:
        repo_url: Git repository URL
        ref: Branch name, tag, or commit SHA

    Returns:
        Full commit SHA

    Raises:
        VendorizeError: If ref cannot be resolved
    """
    # If it's already a full SHA, return it
    if len(ref) == 40 and all(c in "0123456789abcdef" for c in ref.lower()):
        logger.debug(f"Ref '{ref}' is already a full SHA")
        return ref

    logger.info(f"Resolving ref '{ref}' in {repo_url}")

    # Try to resolve as branch or tag
    try:
        output = run_cmd(["git", "ls-remote", repo_url, ref])
        if output:
            sha = output.split()[0]
            logger.info(f"Resolved '{ref}' to {sha}")
            return sha
    except VendorizeError:
        pass

    # Try with refs/heads/ prefix for branches
    try:
        output = run_cmd(["git", "ls-remote", repo_url, f"refs/heads/{ref}"])
        if output:
            sha = output.split()[0]
            logger.info(f"Resolved branch '{ref}' to {sha}")
            return sha
    except VendorizeError:
        pass

    # Try with refs/tags/ prefix for tags
    try:
        output = run_cmd(["git", "ls-remote", repo_url, f"refs/tags/{ref}"])
        if output:
            sha = output.split()[0]
            logger.info(f"Resolved tag '{ref}' to {sha}")
            return sha
    except VendorizeError:
        pass

    raise VendorizeError(f"Could not resolve ref '{ref}' in repository '{repo_url}'")


def load_manifest() -> Dict[str, Any]:
    """
    Load the dependencies.yaml manifest file.

    Returns:
        Parsed manifest data

    Raises:
        VendorizeError: If manifest cannot be loaded
    """
    if not MANIFEST_FILE.exists():
        raise VendorizeError(f"Manifest file {MANIFEST_FILE} not found")

    try:
        with open(MANIFEST_FILE, "r") as f:
            return yaml.safe_load(f)
    except yaml.YAMLError as e:
        raise VendorizeError(f"Failed to parse manifest: {e}")


def create_lockfile(manifest: Dict[str, Any]) -> Dict[str, Any]:
    """
    Create a lockfile with resolved commit SHAs from the manifest.

    Args:
        manifest: Parsed manifest data

    Returns:
        Lockfile data with resolved commits
    """
    logger.info("Creating lockfile with resolved commits...")

    lock_data = {
        "odoo": {},
        "python_requirements": manifest.get("python_requirements", "requirements.txt"),
        "addons": {},
    }

    # Resolve Odoo commit
    if "odoo" in manifest:
        odoo_config = manifest["odoo"]
        lock_data["odoo"] = {
            "url": odoo_config["url"],
            "ref": odoo_config["ref"],
            "commit": resolve_ref(odoo_config["url"], odoo_config["ref"]),
        }

    # Resolve addon commits
    for name, repo_config in manifest.get("addons", {}).items():
        logger.info(f"Processing addon repository: {name}")
        lock_entry = repo_config.copy()
        lock_entry["commit"] = resolve_ref(repo_config["url"], repo_config["ref"])
        lock_data["addons"][name] = lock_entry

    # Write lockfile
    with open(LOCKFILE, "w") as f:
        yaml.dump(lock_data, f, sort_keys=False, default_flow_style=False)

    logger.info(f"Lockfile written to {LOCKFILE}")
    return lock_data


def clone_and_checkout(
    repo_url: str,
    commit: str,
    dest_dir: Path,
    use_cache: bool = True,
    original_ref: str = None,
) -> None:
    """
    Clone a repository and checkout a specific commit, with optional caching.

    Args:
        repo_url: Git repository URL
        commit: Commit SHA to checkout
        dest_dir: Destination directory
        use_cache: Whether to use cached clones for speed
        original_ref: Original branch/tag ref that was resolved to this commit (for smart shallow cloning)
    """
    # For cache-enabled operations, check if we already have the repo
    if use_cache and dest_dir.exists() and (dest_dir / ".git").exists():
        logger.info(f"Using cached repository at {dest_dir}, fetching updates...")
        try:
            # Try to checkout the specific commit first
            try:
                run_cmd(["git", "checkout", commit], cwd=dest_dir)
                logger.info(f"Successfully checked out {commit[:8]} from cache")
                return
            except VendorizeError:
                # If direct checkout fails, we need to fetch more data
                if original_ref and original_ref != commit:
                    # If we have original ref, fetch that branch specifically
                    logger.debug(
                        f"Fetching branch '{original_ref}' for commit {commit[:8]}"
                    )
                    try:
                        run_cmd(
                            ["git", "fetch", "--depth", "1", "origin", original_ref],
                            cwd=dest_dir,
                        )
                        run_cmd(["git", "checkout", commit], cwd=dest_dir)
                        logger.info(
                            f"Successfully checked out {commit[:8]} after fetching {original_ref}"
                        )
                        return
                    except VendorizeError:
                        pass

                # Last resort: unshallow and fetch all
                logger.debug("Unshallowing cached repository")
                run_cmd(["git", "fetch", "--unshallow"], cwd=dest_dir)
                run_cmd(["git", "checkout", commit], cwd=dest_dir)
                logger.info(
                    f"Successfully checked out {commit[:8]} after unshallowing cache"
                )
                return
        except VendorizeError:
            logger.warning(f"Failed to use cache for {dest_dir}, will re-clone")
            shutil.rmtree(dest_dir)

    # Remove destination if it exists (and we're not using cache or cache failed)
    if dest_dir.exists():
        shutil.rmtree(dest_dir)

    logger.info(f"Cloning {repo_url} at {commit[:8]} to {dest_dir}")

    # Use original_ref for smarter shallow cloning when available
    if original_ref and original_ref != commit:
        logger.debug(
            f"Using shallow clone of branch '{original_ref}' for commit {commit[:8]}"
        )
        try:
            # Clone the specific branch/tag that contains our commit
            run_cmd(
                [
                    "git",
                    "clone",
                    "--depth",
                    "1",
                    "--branch",
                    original_ref,
                    repo_url,
                    str(dest_dir),
                ]
            )
            # The commit should be available now since we cloned the right branch
            run_cmd(["git", "checkout", commit], cwd=dest_dir)
            logger.debug(
                f"Successfully checked out {commit[:8]} from branch {original_ref}"
            )
            return
        except VendorizeError:
            logger.warning(
                f"Failed to clone branch '{original_ref}', falling back to default strategy"
            )
            # Clean up failed attempt
            if dest_dir.exists():
                shutil.rmtree(dest_dir)

    # Fallback: shallow clone of default branch
    logger.debug(f"Using shallow clone of default branch for {commit[:8]}")
    run_cmd(["git", "clone", "--depth", "1", repo_url, str(dest_dir)])

    # Try to checkout the specific commit
    try:
        run_cmd(["git", "checkout", commit], cwd=dest_dir)
        logger.debug(f"Successfully checked out {commit[:8]} from shallow clone")
    except VendorizeError:
        # If shallow clone doesn't have the commit, fetch it specifically
        logger.info(f"Shallow clone missing {commit[:8]}, fetching specifically")
        try:
            # Try to fetch the specific commit with minimal depth
            run_cmd(["git", "fetch", "--depth", "1", "origin", commit], cwd=dest_dir)
            run_cmd(["git", "checkout", commit], cwd=dest_dir)
        except VendorizeError:
            # Last resort: unshallow the repository (but still better than full initial clone)
            logger.warning(f"Unshallowing repository to find {commit[:8]}")
            run_cmd(["git", "fetch", "--unshallow"], cwd=dest_dir)
            run_cmd(["git", "checkout", commit], cwd=dest_dir)

    # For final vendor directory, remove .git to save space
    # But keep it for cache directory
    if not use_cache:
        git_dir = dest_dir / ".git"
        if git_dir.exists():
            shutil.rmtree(git_dir)


def find_odoo_modules(directory: Path) -> List[str]:
    """
    Find all valid Odoo modules in a directory.

    Args:
        directory: Directory to search

    Returns:
        List of module directory names
    """
    modules = []
    for item in directory.iterdir():
        if item.is_dir() and not item.name.startswith("."):
            # Check for Odoo module manifest files
            if (item / "__manifest__.py").exists() or (
                item / "__openerp__.py"
            ).exists():
                modules.append(item.name)
    return sorted(modules)


def sync_from_lockfile(
    lockfile_data: Dict[str, Any], clean_cache: bool = False
) -> None:
    """
    Sync all dependencies from the lockfile to the vendor directory.

    Args:
        lockfile_data: Parsed lockfile data
        clean_cache: Whether to clean the cache directory before syncing
    """
    logger.info("Syncing dependencies from lockfile...")

    # Clean vendor directory
    if VENDOR_DIR.exists():
        logger.info(f"Removing existing vendor directory: {VENDOR_DIR}")
        shutil.rmtree(VENDOR_DIR)

    VENDOR_DIR.mkdir(parents=True)
    ADDONS_DEST_DIR.mkdir(parents=True)

    # Handle cache directory
    if clean_cache and TMP_DIR.exists():
        logger.info(f"Cleaning cache directory: {TMP_DIR}")
        shutil.rmtree(TMP_DIR)

    # Create temp directory for cloning (will be kept for caching)
    TMP_DIR.mkdir(parents=True, exist_ok=True)

    try:
        # Clone Odoo (don't use cache for final destination)
        if "odoo" in lockfile_data and lockfile_data["odoo"]:
            odoo_config = lockfile_data["odoo"]
            logger.info("Vendoring Odoo core...")
            clone_and_checkout(
                odoo_config["url"],
                odoo_config["commit"],
                ODOO_DEST_DIR,
                use_cache=False,  # Don't cache the final vendor directory
                original_ref=odoo_config.get(
                    "ref"
                ),  # Use original ref for smart shallow cloning
            )

        # Clone and process addon repositories
        for name, repo_config in lockfile_data.get("addons", {}).items():
            logger.info(f"Vendoring addon repository: {name}")

            # Clone to temp directory (with caching)
            temp_clone_dir = TMP_DIR / name
            clone_and_checkout(
                repo_config["url"],
                repo_config["commit"],
                temp_clone_dir,
                use_cache=True,  # Use cache for temp clones
                original_ref=repo_config.get(
                    "ref"
                ),  # Use original ref for smart shallow cloning
            )

            # Determine which modules to copy
            dest_addon_dir = ADDONS_DEST_DIR / name
            dest_addon_dir.mkdir(parents=True, exist_ok=True)

            if "modules" in repo_config and repo_config["modules"]:
                # Copy only specified modules
                modules_to_copy = repo_config["modules"]
                logger.info(f"Copying specific modules: {modules_to_copy}")

                for module_name in modules_to_copy:
                    src_module = temp_clone_dir / module_name
                    if src_module.exists():
                        dest_module = dest_addon_dir / module_name
                        shutil.copytree(src_module, dest_module)
                        logger.debug(f"Copied module: {module_name}")
                    else:
                        logger.warning(f"Module '{module_name}' not found in {name}")
            else:
                # Auto-discover and copy all modules
                modules = find_odoo_modules(temp_clone_dir)
                logger.info(f"Auto-discovered {len(modules)} modules")

                for module_name in modules:
                    src_module = temp_clone_dir / module_name
                    dest_module = dest_addon_dir / module_name
                    shutil.copytree(src_module, dest_module)
                    logger.debug(f"Copied module: {module_name}")

    finally:
        # Don't clean up temp directory - keep it for caching
        logger.debug(f"Keeping cache directory for faster subsequent builds: {TMP_DIR}")

    logger.info("Vendoring complete!")

    # Display summary
    total_modules = sum(
        len(list(addon_dir.iterdir()))
        for addon_dir in ADDONS_DEST_DIR.iterdir()
        if addon_dir.is_dir()
    )
    logger.info(f"Vendored Odoo core and {total_modules} addon modules")


def create_source_tarball(version: str) -> Path:
    """
    Create a source tarball from the vendor directory.

    Args:
        version: Version string for the tarball name

    Returns:
        Path to the created tarball
    """
    if not VENDOR_DIR.exists():
        raise VendorizeError("Vendor directory does not exist. Run --sync first.")

    tarball_name = f"openspp-{version}-source.tar.gz"
    tarball_path = Path(tarball_name)

    logger.info(f"Creating source tarball: {tarball_name}")

    with tarfile.open(tarball_path, "w:gz") as tar:
        # Add vendor directory contents
        tar.add(VENDOR_DIR, arcname=f"openspp-{version}")

        # Add requirements.txt if it exists
        if Path("requirements.txt").exists():
            tar.add("requirements.txt", arcname=f"openspp-{version}/requirements.txt")

        # Add setup files
        for setup_file in ["setup.py", "setup.cfg", "pyproject.toml"]:
            if Path(setup_file).exists():
                tar.add(setup_file, arcname=f"openspp-{version}/{setup_file}")

    size_mb = tarball_path.stat().st_size / (1024 * 1024)
    logger.info(f"Source tarball created: {tarball_name} ({size_mb:.1f} MB)")

    return tarball_path


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="OpenSPP dependency vendoring tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )

    parser.add_argument(
        "--lock",
        action="store_true",
        help="Resolve refs to commits and create/update lockfile",
    )

    parser.add_argument(
        "--sync", action="store_true", help="Sync dependencies from existing lockfile"
    )

    parser.add_argument("--clean", action="store_true", help="Remove vendor directory")

    parser.add_argument(
        "--clean-cache",
        action="store_true",
        help="Remove cache directory to force fresh clones",
    )

    parser.add_argument(
        "--tarball",
        metavar="VERSION",
        help="Create source tarball with specified version",
    )

    parser.add_argument("--verbose", action="store_true", help="Enable verbose logging")

    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    try:
        if args.clean:
            if VENDOR_DIR.exists():
                logger.info(f"Removing vendor directory: {VENDOR_DIR}")
                shutil.rmtree(VENDOR_DIR)
            else:
                logger.info("Vendor directory does not exist")

        elif args.clean_cache:
            if TMP_DIR.exists():
                logger.info(f"Removing cache directory: {TMP_DIR}")
                shutil.rmtree(TMP_DIR)
            else:
                logger.info("Cache directory does not exist")

        elif args.lock:
            manifest = load_manifest()
            lockfile_data = create_lockfile(manifest)
            sync_from_lockfile(
                lockfile_data,
                clean_cache=args.clean_cache if "clean_cache" in args else False,
            )

        elif args.sync:
            if not LOCKFILE.exists():
                raise VendorizeError(
                    f"Lockfile {LOCKFILE} not found. Run --lock first."
                )

            with open(LOCKFILE, "r") as f:
                lockfile_data = yaml.safe_load(f)

            sync_from_lockfile(
                lockfile_data,
                clean_cache=args.clean_cache if "clean_cache" in args else False,
            )

        elif args.tarball:
            tarball_path = create_source_tarball(args.tarball)
            print(f"Created: {tarball_path}")

        else:
            parser.print_help()
            sys.exit(1)

    except VendorizeError as e:
        logger.error(f"Error: {e}")
        sys.exit(1)
    except KeyboardInterrupt:
        logger.info("Interrupted by user")
        sys.exit(130)
    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
