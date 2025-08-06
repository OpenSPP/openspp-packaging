# OpenSPP Docker Image
# Based on Official Odoo 17.0 image

FROM odoo:17.0

# Metadata
LABEL maintainer="OpenSPP Contributors <info@openspp.org>"
LABEL org.opencontainers.image.title="OpenSPP"
LABEL org.opencontainers.image.description="Open Source Social Protection Platform"
LABEL org.opencontainers.image.url="https://openspp.org"
LABEL org.opencontainers.image.source="https://github.com/OpenSPP/openspp-modules"
LABEL org.opencontainers.image.documentation="https://docs.openspp.org"

# Build arguments
ARG VERSION=17.0.1
ARG DEBIAN_FRONTEND=noninteractive

# Environment variables
ENV OPENSPP_VERSION=${VERSION} \
    ODOO_VERSION=17.0 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Switch to root for installation
USER root

# Install additional system dependencies for OpenSPP
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        # Basic utilities first
        git \
        curl \
        wget \
        vim \
        # Build tools
        python3-dev \
        gcc \
        g++ \
    && apt-get install -y --no-install-recommends \
        # Image processing
        libzbar0 \
        libzbar-dev \
    && apt-get install -y --no-install-recommends \
        # Geospatial libraries (install separately as they can be more fragile)
        gdal-bin \
        libgdal-dev \
        libgeos-dev \
        libproj-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install additional Python packages for OpenSPP
COPY requirements.txt /tmp/openspp-requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/openspp-requirements.txt && \
    rm /tmp/openspp-requirements.txt

# Create directories for OpenSPP
RUN mkdir -p /mnt/openspp-addons \
    && mkdir -p /var/lib/openspp/data \
    && mkdir -p /var/lib/openspp/sessions \
    && mkdir -p /etc/openspp

# Copy OpenSPP modules
COPY --chown=odoo:odoo ./openspp/addons /mnt/openspp-addons

# Copy configuration template
COPY --chown=odoo:odoo setup/docker/openspp.conf /etc/openspp/openspp.conf.template

# Copy custom entrypoint
COPY --chown=odoo:odoo setup/docker/entrypoint.sh /openspp-entrypoint.sh
RUN chmod +x /openspp-entrypoint.sh

# Set ownership
RUN chown -R odoo:odoo /mnt/openspp-addons \
    && chown -R odoo:odoo /var/lib/openspp \
    && chown -R odoo:odoo /etc/openspp

# Switch back to odoo user
USER odoo

# Volumes
VOLUME ["/var/lib/openspp/data", "/mnt/extra-addons", "/etc/openspp"]

# Expose ports
EXPOSE 8069 8071 8072

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8069/web/health || exit 1

# Set working directory
WORKDIR /var/lib/openspp

# Entrypoint and default command
ENTRYPOINT ["/openspp-entrypoint.sh"]
CMD ["odoo"]