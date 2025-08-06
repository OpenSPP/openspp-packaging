#!/usr/bin/env python3
# Part of OpenSPP. See LICENSE file for full copyright and licensing details.

import argparse
import logging
import os
import shutil
import subprocess
import sys
import tempfile
import time
import traceback

from pathlib import Path

# ----------------------------------------------------------
# Utils
# ----------------------------------------------------------

ROOTDIR = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
TSTAMP = time.strftime("%Y%m%d", time.gmtime())
TSEC = time.strftime("%H%M%S", time.gmtime())

# Get version info from release.py
version = ...
version_info = ...
nt_service_name = ...
exec(open(os.path.join(ROOTDIR, "openspp", "release.py"), "rb").read())
VERSION = version.split("-")[0].replace("saas~", "")
GPGPASSPHRASE = os.getenv("GPGPASSPHRASE")
GPGID = os.getenv("GPGID")
DOCKERVERSION = VERSION.replace("+", "")

# ----------------------------------------------------------
# Logging
# ----------------------------------------------------------

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# ----------------------------------------------------------
# Package builders
# ----------------------------------------------------------


def build_python_package():
    """Build Python wheel and source distribution"""
    logger.info("Building Python package...")
    os.chdir(ROOTDIR)

    # Clean previous builds
    for dir in ["build", "dist", "openspp.egg-info"]:
        if os.path.exists(dir):
            shutil.rmtree(dir)

    # Build wheel and sdist
    subprocess.check_call([sys.executable, "setup.py", "sdist", "bdist_wheel"])
    logger.info(f"Python package built: dist/openspp-{VERSION}.tar.gz")
    logger.info(f"Python wheel built: dist/openspp-{VERSION}-py3-none-any.whl")


def build_rpm():
    """Build RPM package"""
    logger.info("Building RPM package...")

    # Create build directories
    rpmbuild_dir = os.path.expanduser("~/rpmbuild")
    for subdir in ["BUILD", "RPMS", "SOURCES", "SPECS", "SRPMS"]:
        os.makedirs(os.path.join(rpmbuild_dir, subdir), exist_ok=True)

    # Create source tarball
    os.chdir(ROOTDIR)
    tarball = f"openspp-{VERSION}.tar.gz"
    subprocess.check_call(
        [
            "tar",
            "czf",
            os.path.join(rpmbuild_dir, "SOURCES", tarball),
            "--exclude=.git",
            "--exclude=*.pyc",
            "--exclude=__pycache__",
            "--transform",
            f"s,^,openspp-{VERSION}/,",
            ".",
        ]
    )

    # Copy spec file
    shutil.copy(
        os.path.join(ROOTDIR, "setup/rpm/openspp.spec"),
        os.path.join(rpmbuild_dir, "SPECS/"),
    )

    # Build RPM
    subprocess.check_call(
        [
            "rpmbuild",
            "-ba",
            "--define",
            f"version {VERSION}",
            os.path.join(rpmbuild_dir, "SPECS/openspp.spec"),
        ]
    )

    logger.info(f"RPM package built in {rpmbuild_dir}/RPMS/")


def build_deb():
    """Build Debian package"""
    logger.info("Building Debian package...")

    # Create build directory
    build_dir = tempfile.mkdtemp(prefix="openspp-deb-")
    pkg_dir = os.path.join(build_dir, f"openspp-{VERSION}")

    try:
        # Copy source
        shutil.copytree(
            ROOTDIR,
            pkg_dir,
            ignore=shutil.ignore_patterns(".git", "*.pyc", "__pycache__"),
        )

        # Copy debian files
        debian_src = os.path.join(ROOTDIR, "setup/debian")
        debian_dst = os.path.join(pkg_dir, "debian")
        shutil.copytree(debian_src, debian_dst)

        # Update changelog
        changelog_file = os.path.join(debian_dst, "changelog")
        if os.path.exists(changelog_file):
            with open(changelog_file, "r") as f:
                changelog = f.read()
            changelog = changelog.replace("VERSION", VERSION)
            changelog = changelog.replace(
                "TIMESTAMP", time.strftime("%a, %d %b %Y %H:%M:%S +0000", time.gmtime())
            )
            with open(changelog_file, "w") as f:
                f.write(changelog)

        # Build package
        os.chdir(pkg_dir)
        subprocess.check_call(["dpkg-buildpackage", "-us", "-uc"])

        # Copy built package
        deb_file = f"openspp_{VERSION}_all.deb"
        shutil.copy(os.path.join(build_dir, deb_file), os.path.join(ROOTDIR, "dist/"))

        logger.info(f"Debian package built: dist/{deb_file}")

    finally:
        shutil.rmtree(build_dir)


def build_windows():
    """Build Windows installer using Wine or native Windows"""
    logger.info("Building Windows installer...")

    # Check if we're on Windows or using Wine on Linux
    if sys.platform == "win32":
        # Native Windows build
        nsis_cmd = "makensis"
    else:
        # Check for Wine and NSIS
        wine_path = shutil.which("wine")
        if not wine_path:
            logger.error(
                "Wine not found. Install Wine to build Windows installer on Linux"
            )
            logger.info("Install with: sudo apt-get install wine wine32 wine64")
            return

        # Check for NSIS in Wine
        wine_nsis = os.path.expanduser(
            "~/.wine/drive_c/Program Files (x86)/NSIS/makensis.exe"
        )
        wine_nsis_alt = os.path.expanduser(
            "~/.wine/drive_c/Program Files/NSIS/makensis.exe"
        )

        if os.path.exists(wine_nsis):
            nsis_cmd = f'wine "{wine_nsis}"'
        elif os.path.exists(wine_nsis_alt):
            nsis_cmd = f'wine "{wine_nsis_alt}"'
        else:
            logger.error("NSIS not found in Wine. Please install NSIS in Wine")
            logger.info("Download NSIS installer and run: wine nsis-installer.exe")
            return

    # Update version in NSIS script
    nsi_file = os.path.join(ROOTDIR, "setup/windows/openspp.nsi")
    with open(nsi_file, "r") as f:
        nsi_content = f.read()
    nsi_content = nsi_content.replace("{{VERSION}}", VERSION)

    temp_nsi = os.path.join(ROOTDIR, "setup/windows/openspp_temp.nsi")
    with open(temp_nsi, "w") as f:
        f.write(nsi_content)

    # Build installer
    # Use shell=True for Wine commands, False for native Windows
    use_shell = sys.platform != "win32"
    try:
        if use_shell:
            # Wine on Linux
            subprocess.check_call(f"{nsis_cmd} {temp_nsi}", shell=True)
        else:
            # Native Windows
            subprocess.check_call([nsis_cmd, temp_nsi])
    finally:
        if os.path.exists(temp_nsi):
            os.remove(temp_nsi)

    installer_name = f"openspp-{VERSION}-setup.exe"
    logger.info(f"Windows installer built: dist/{installer_name}")


def build_docker():
    """Build Docker image"""
    logger.info("Building Docker image...")

    os.chdir(os.path.join(ROOTDIR, "setup/docker"))

    # Build image
    tag = f"openspp/openspp:{DOCKERVERSION}"
    subprocess.check_call(
        ["docker", "build", "--build-arg", f"VERSION={VERSION}", "-t", tag, "."]
    )

    # Tag as latest
    subprocess.check_call(["docker", "tag", tag, "openspp/openspp:latest"])

    logger.info(f"Docker image built: {tag}")


def sign_packages():
    """Sign packages with GPG"""
    if not GPGID:
        logger.warning("GPGID not set, skipping package signing")
        return

    logger.info("Signing packages...")
    dist_dir = os.path.join(ROOTDIR, "dist")

    for file in os.listdir(dist_dir):
        file_path = os.path.join(dist_dir, file)
        if os.path.isfile(file_path) and not file.endswith(".asc"):
            sig_file = f"{file_path}.asc"
            if os.path.exists(sig_file):
                os.remove(sig_file)

            cmd = ["gpg", "--armor", "--detach-sign"]
            if GPGPASSPHRASE:
                cmd.extend(["--batch", "--passphrase", GPGPASSPHRASE])
            cmd.extend(["--local-user", GPGID, file_path])

            subprocess.check_call(cmd)
            logger.info(f"Signed: {file}")


# ----------------------------------------------------------
# Main
# ----------------------------------------------------------


def main():
    parser = argparse.ArgumentParser(description="OpenSPP Packaging Tool")
    parser.add_argument(
        "--build",
        choices=["all", "python", "rpm", "deb", "windows", "docker"],
        default="all",
        help="What to build",
    )
    parser.add_argument("--sign", action="store_true", help="Sign packages with GPG")
    parser.add_argument("--version", action="version", version=VERSION)

    args = parser.parse_args()

    # Ensure dist directory exists
    os.makedirs(os.path.join(ROOTDIR, "dist"), exist_ok=True)

    try:
        if args.build in ["all", "python"]:
            build_python_package()

        if args.build in ["all", "rpm"]:
            if sys.platform.startswith("linux"):
                build_rpm()
            else:
                logger.warning("RPM build only supported on Linux")

        if args.build in ["all", "deb"]:
            if sys.platform.startswith("linux"):
                build_deb()
            else:
                logger.warning("DEB build only supported on Linux")

        if args.build in ["all", "windows"]:
            build_windows()

        if args.build in ["all", "docker"]:
            build_docker()

        if args.sign:
            sign_packages()

        logger.info("Build completed successfully!")

    except Exception as e:
        logger.error(f"Build failed: {e}")
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
