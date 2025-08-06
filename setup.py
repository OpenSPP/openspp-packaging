#!/usr/bin/env python
# -*- coding: utf-8 -*-

from setuptools import find_packages, setup
from os.path import join, dirname

def parse_requirements(filename):
    """Load requirements from a pip requirements file."""
    with open(join(dirname(__file__), filename)) as f:
        requirements = []
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and not line.startswith('via'):
                # Skip comment-like lines (like '# via rasterio')
                if '# via' not in line and 'via -r' not in line:
                    requirements.append(line)
    
    # Add odoo as a prerequisite (not in requirements.txt since it's vendored)
    requirements.insert(0, 'odoo>=17.0')
    return requirements

# Load release variables
exec(open(join(dirname(__file__), 'openspp', 'release.py'), 'rb').read())

setup(
    name='openspp',
    version=version,
    description=description,
    long_description=long_desc,
    long_description_content_type='text/markdown',
    url=url,
    author=author,
    author_email=author_email,
    classifiers=[c for c in classifiers.split('\n') if c],
    license=license,
    scripts=['setup/openspp'],
    packages=find_packages(),
    package_dir={'openspp': 'openspp'},
    include_package_data=True,
    install_requires=parse_requirements('requirements.txt'),
    python_requires='>=3.10',
    extras_require={
        'ldap': ['python-ldap'],
        'dev': [
            'pytest',
            'pytest-odoo',
            'coverage',
            'flake8',
            'pre-commit',
        ],
    },
    entry_points={
        'console_scripts': [
            'openspp=openspp.cli:main',
        ],
    },
)