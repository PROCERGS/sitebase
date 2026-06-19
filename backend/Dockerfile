# syntax=docker/dockerfile:1
ARG PLONE_VERSION=6.1.1
ARG PROD_CONFIG_IMAGE=plone/server-prod-config:6.1.1
FROM plone/server-builder:${PLONE_VERSION} AS builder

WORKDIR /app

# Add local code
COPY scripts/ scripts/
COPY . src

# Install local requirements and pre-compile mo files
ARG ADD_PACKAGES=""
RUN <<EOT
    set -e
    bin/pip install mxdev uv
    sed -i 's/-e .\[test\]/./g' src/mx.ini
    cd /app/src
    # remove potentially existing virtualenv from local build
    rm -rf .venv
    ../bin/mxdev -c mx.ini
    ../bin/uv pip install -r requirements-mxdev.txt
    bash /app/scripts/add_packages.sh "../bin/uv" "${ADD_PACKAGES}"
    ../bin/python /compile_mo.py
EOT

FROM ${PROD_CONFIG_IMAGE}

LABEL maintainer="procergs <sites@procergs.rs.gov.br>" \
      org.label-schema.name="sitebase-backend" \
      org.label-schema.description="Sitebase backend image." \
      org.label-schema.vendor="procergs"

# Copy /app from builder
COPY --from=builder /app /app

RUN <<EOT
    set -e
    ln -s /data /app/var
    # Ensure group 0 (root) can access everything — required for
    # OpenShift's random UID (which runs in gid 0).
    chgrp -R 0 /app
    chmod -R g=u /app
EOT

ENTRYPOINT ["/app/scripts/sitebase-entrypoint.sh"]
