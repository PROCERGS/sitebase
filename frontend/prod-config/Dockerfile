# syntax=docker/dockerfile:1

ARG NODE_VERSION=20
FROM node:${NODE_VERSION}-trixie-slim

LABEL maintainer="PROCERGS <sites@procergs.rs.gov.br>" \
      org.label-schema.name="sitebase-frontend-prod-config-debian" \
      org.label-schema.description="Volto/Plone frontend production base using Debian Trixie Node.js 20" \
      org.label-schema.vendor="Plone Foundation + PROCERGS"

# Install runtime dependencies (following official Plone structure)
RUN <<EOT
    set -e
    apt-get update
    apt-get install -y --no-install-recommends busybox wget git ca-certificates
    busybox --install -s
    apt-get clean -y
    rm -rf /var/lib/apt/lists/* /usr/share/doc
    mkdir -p /app
    chown -R node:node /app
EOT

# Update npm to a version whose bundled tar and glob dependencies are patched.
ARG NPM_VERSION=11.18.0
RUN npm install --global "npm@${NPM_VERSION}" && \
    npm cache clean --force

# Install and enable corepack for pnpm (official Plone requirement)
RUN npm i -g corepack@latest && corepack enable

# Run the image with user node
USER node

# Set working directory to /app
WORKDIR /app

# Pre-download a pnpm release whose bundled tar and glob are patched.
ARG PNPM_VERSION=10.34.5
RUN corepack install --global "pnpm@${PNPM_VERSION}" && \
    pnpm --version

# Expose default Express port
EXPOSE 3000

# Set healthcheck to port 3000
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s CMD [ -n "$LISTEN_PORT" ] || LISTEN_PORT=3000 ; wget -q http://127.0.0.1:"$LISTEN_PORT" -O - || exit 1

# Environment variables for production
ENV NODE_ENV=production
ENV RAZZLE_NODE_ENV=production

# Entrypoint would be pnpm (official Plone standard)
ENTRYPOINT ["pnpm"]

# And the image will run in production mode (official Plone standard)
CMD ["start:prod"]
