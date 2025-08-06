%global name openspp
%global release 1
%global unmangled_version %{version}

Summary: OpenSPP - Open Source Social Protection Platform
Name: %{name}
Version: %{version}
Release: %{release}
Source0: %{name}-%{unmangled_version}.tar.gz
License: LGPL-3
Group: Development/Libraries
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Prefix: %{_prefix}
BuildArch: noarch
Vendor: OpenSPP Contributors <info@openspp.org>
Requires: odoo >= 17.0
Requires: python3 >= 3.10
Requires: postgresql >= 12
Requires: postgresql-server >= 12
Requires: python3-pip
Requires: sassc
Requires: nodejs
BuildRequires: python3-devel
BuildRequires: pyproject-rpm-macros
Url: https://openspp.org

%description
OpenSPP (Open Source Social Protection Platform) is a comprehensive suite of modules
built on top of Odoo 17.0 that provides digital solutions for social protection programs.

It includes features for beneficiary registry management, program enrollment and eligibility,
cash and in-kind entitlement management, payment processing, grievance handling,
monitoring and reporting, and integration with external systems.

OpenSPP is designed to be scalable, secure, and adaptable to different country contexts
and social protection program types.

%generate_buildrequires
%pyproject_buildrequires

%prep
%autosetup

%build
%py3_build

%install
%py3_install

# Create directories
mkdir -p %{buildroot}/etc/openspp
mkdir -p %{buildroot}/var/lib/openspp
mkdir -p %{buildroot}/var/log/openspp
mkdir -p %{buildroot}/usr/lib/systemd/system

# Install configuration file
cat > %{buildroot}/etc/openspp/openspp.conf << EOF
[options]
; This is the password that allows database operations:
; admin_passwd = admin
db_host = localhost
db_port = 5432
db_user = openspp
db_password = False

; OpenSPP addons path (includes both Odoo and OpenSPP modules)
addons_path = %{python3_sitelib}/odoo/addons,%{python3_sitelib}/openspp/addons

; Server configuration
http_port = 8069
longpolling_port = 8072

; Logging
log_level = info
log_file = /var/log/openspp/openspp.log

; OpenSPP specific settings
default_productivity_apps = True
EOF

# Install systemd service file
cat > %{buildroot}/usr/lib/systemd/system/openspp.service << EOF
[Unit]
Description=OpenSPP - Open Source Social Protection Platform
After=network.target postgresql.service

[Service]
Type=simple
User=openspp
Group=openspp
ExecStart=/usr/bin/openspp --config /etc/openspp/openspp.conf
KillMode=mixed
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

%pre
# Create openspp user and group if they don't exist
if ! getent group openspp > /dev/null 2>&1; then
    groupadd -r openspp
fi

if ! getent passwd openspp > /dev/null 2>&1; then
    useradd -r -g openspp -d /var/lib/openspp -s /sbin/nologin \
        -c "OpenSPP Server" openspp
fi

%post
#!/bin/sh

set -e

OPENSPP_CONFIGURATION_DIR=/etc/openspp
OPENSPP_CONFIGURATION_FILE=$OPENSPP_CONFIGURATION_DIR/openspp.conf
OPENSPP_DATA_DIR=/var/lib/openspp
OPENSPP_GROUP="openspp"
OPENSPP_LOG_DIR=/var/log/openspp
OPENSPP_LOG_FILE=$OPENSPP_LOG_DIR/openspp.log
OPENSPP_USER="openspp"

# Set proper ownership
chown -R $OPENSPP_USER:$OPENSPP_GROUP $OPENSPP_DATA_DIR
chown -R $OPENSPP_USER:$OPENSPP_GROUP $OPENSPP_LOG_DIR
chown $OPENSPP_USER:$OPENSPP_GROUP $OPENSPP_CONFIGURATION_FILE

# Set proper permissions
chmod 0750 $OPENSPP_DATA_DIR
chmod 0750 $OPENSPP_LOG_DIR
chmod 0640 $OPENSPP_CONFIGURATION_FILE

# Register openspp user as a PostgreSQL user with "Create DB" role attribute
if systemctl is-active --quiet postgresql; then
    su - postgres -c "createuser -d -R -S $OPENSPP_USER" 2> /dev/null || true
fi

# Reload systemd to recognize new service
systemctl daemon-reload

# Enable service (but don't start it)
systemctl enable openspp.service

echo ""
echo "OpenSPP has been installed successfully!"
echo ""
echo "To complete the setup:"
echo "1. Configure PostgreSQL if not already done"
echo "2. Edit /etc/openspp/openspp.conf to set your database password"
echo "3. Initialize the database: openspp --config /etc/openspp/openspp.conf --init base"
echo "4. Start the service: systemctl start openspp"
echo ""

%preun
if [ $1 -eq 0 ]; then
    # This is an uninstall
    systemctl stop openspp.service 2> /dev/null || true
    systemctl disable openspp.service 2> /dev/null || true
fi

%postun
if [ $1 -eq 0 ]; then
    # This is an uninstall
    # Remove PostgreSQL user
    if systemctl is-active --quiet postgresql; then
        su - postgres -c "dropuser openspp" 2> /dev/null || true
    fi
    
    # Remove user and group
    userdel openspp 2> /dev/null || true
    groupdel openspp 2> /dev/null || true
fi

%files
%doc README.md LICENSE
%{python3_sitelib}/openspp*
%{_bindir}/openspp
%config(noreplace) /etc/openspp/openspp.conf
%attr(0750, openspp, openspp) /var/lib/openspp
%attr(0750, openspp, openspp) /var/log/openspp
/usr/lib/systemd/system/openspp.service

%changelog
* Thu Jan 01 2025 OpenSPP Contributors <info@openspp.org> - 17.0.1-1
- Initial RPM package for OpenSPP
- Based on Odoo 17.0 packaging structure
- Includes all OpenSPP modules and dependencies