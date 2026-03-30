# syntax=docker/dockerfile:1
ARG VOLTO_VERSION
ARG PROD_CONFIG_IMAGE=plone/frontend-prod-config:18.23.0
FROM plone/frontend-builder:${VOLTO_VERSION} AS builder

COPY --chown=node scripts/ /app/scripts/
COPY --chown=node packages/volto-procergs-sitebase /app/packages/volto-procergs-sitebase
COPY --chown=node volto.config.js /app/
COPY --chown=node package.json /app/package.json.temp
COPY --chown=node mrs.developer.json /app/
COPY --chown=node pnpm-workspace.yaml /app/

ARG ADD_PACKAGES=""
ARG ADD_ADDONS=""
ARG SET_THEME=""
ARG ADD_MRSDEVELOPER=""
ARG ADD_PNPM_WORKSPACE=""
RUN --mount=type=cache,id=pnpm,target=/app/.pnpm-store,uid=1000 <<EOT
    set -e
    python3 <<PYTHON
import json
orig_data = json.load(open('package.json.temp'))
orig_deps = orig_data['dependencies']
orig_pnpm = orig_data.get('pnpm', {})
data = json.load(open('package.json'))
data['dependencies'].update(orig_deps)
if orig_pnpm:
    data['pnpm'] = orig_pnpm
json.dump(data, open('package.json', 'w'), indent=2)
PYTHON
    rm package.json.temp
    bash /app/scripts/add_packages.sh "${ADD_PACKAGES}"
    bash /app/scripts/add_addons.sh "${ADD_ADDONS}"
    bash /app/scripts/set_theme.sh "${SET_THEME}"
    bash /app/scripts/add_mrsdeveloper.sh "${ADD_MRSDEVELOPER}"
    bash /app/scripts/add_pnpm_workspace.sh "${ADD_PNPM_WORKSPACE}"
    pnpm dlx mrs-developer missdev --no-config --fetch-https
    pnpm install && pnpm build:deps
    pnpm build
    pnpm install --prod
    # Remove vulnerable packages that survive pnpm install --prod or pnpm overrides
    # babel@6 (CVE-2023-45133)
    rm -rf node_modules/.pnpm/babel-traverse@6.26.0 \
           node_modules/.pnpm/babel-plugin-transform-class-properties@6.24.1 \
           node_modules/.pnpm/babel-helper-function-name@6.24.1 \
           node_modules/.pnpm/babel-template@6.26.0 \
           node_modules/.pnpm/babel-types@6.26.0 \
           node_modules/.pnpm/babel-runtime@6.26.0
    # form-data@4.0.3 (CVE-2025-7783) — override exists but package may still be bundled
    rm -rf node_modules/.pnpm/form-data@4.0.3
    # simple-git@3.28.0 (CVE-2026-28292) — build-time dep of mrs-developer, not needed at runtime
    rm -rf node_modules/.pnpm/simple-git@3.28.0
EOT

FROM ${PROD_CONFIG_IMAGE}

LABEL maintainer="PROCERGS <sites@procergs.rs.gov.br>" \
      org.label-schema.name="sitebase-frontend" \
      org.label-schema.description="Project Title frontend image." \
      org.label-schema.vendor="PROCERGS"

COPY --from=builder /app/ /app/

RUN <<EOT
    set -e
    npm i -g corepack@latest && corepack enable pnpm
    corepack use pnpm@9.1.1
    corepack prepare pnpm@9.1.1 --activate
EOT
