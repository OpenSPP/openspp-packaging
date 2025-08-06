# -*- coding: utf-8 -*-
# Part of OpenSPP. See LICENSE file for full copyright and licensing details.

# ABOUTME: Version and release information for OpenSPP
# ABOUTME: This file defines package metadata used by setup.py and packaging scripts

version = "17.0.1"
version_info = (17, 0, 1, "final", 0)
major_version = "17.0"

description = "OpenSPP - Open Source Social Protection Platform"
long_desc = """
OpenSPP (Open Source Social Protection Platform) is a comprehensive suite of modules
built on top of Odoo 17.0 that provides digital solutions for social protection programs.

It includes features for:
- Beneficiary registry management
- Program enrollment and eligibility
- Cash and in-kind entitlement management  
- Payment processing and reconciliation
- Grievance and appeals handling
- Monitoring and reporting
- Integration with external systems

OpenSPP is designed to be scalable, secure, and adaptable to different country contexts
and social protection program types.
"""

url = "https://openspp.org"
author = "OpenSPP Contributors"
author_email = "info@openspp.org"

classifiers = """
Development Status :: 5 - Production/Stable
License :: OSI Approved :: GNU Lesser General Public License v3 (LGPLv3)
Programming Language :: Python
Programming Language :: Python :: 3
Programming Language :: Python :: 3.10
Programming Language :: Python :: 3.11
Programming Language :: Python :: 3.12
Framework :: Odoo
Framework :: Odoo :: 17.0
Intended Audience :: Government
Intended Audience :: End Users/Desktop
Topic :: Office/Business
Topic :: Software Development :: Libraries :: Application Frameworks
"""

license = "LGPL-3"

nt_service_name = "openspp-server-" + major_version.replace(".", "-")
