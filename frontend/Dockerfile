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

# Project selection is used only while compiling the frontend.
ARG PROJECT_ID=""
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
orig_package_manager = orig_data.get('packageManager')
data = json.load(open('package.json'))
data['dependencies'].update(orig_deps)
if orig_pnpm:
    data['pnpm'] = orig_pnpm
if orig_package_manager:
    data['packageManager'] = orig_package_manager
json.dump(data, open('package.json', 'w'), indent=2)
PYTHON
    rm package.json.temp
    bash /app/scripts/add_packages.sh "${ADD_PACKAGES}"
    bash /app/scripts/add_addons.sh "${ADD_ADDONS}"
    bash /app/scripts/set_theme.sh "${SET_THEME}"
    bash /app/scripts/add_mrsdeveloper.sh "${ADD_MRSDEVELOPER}"
    bash /app/scripts/add_pnpm_workspace.sh "${ADD_PNPM_WORKSPACE}"
EOT

# Mount GitHub credentials only while fetching addon sources, before install/build.
RUN --mount=type=cache,id=pnpm,target=/app/.pnpm-store,uid=1000 \
    --mount=type=secret,id=github_token,uid=1000 <<EOT
    set -eu
    if [ -s /run/secrets/github_token ]; then
        # Reset inherited helpers and provide credentials only for HTTPS GitHub.
        # Environment config avoids writing the token to Git config or clone URLs.
        export GIT_CONFIG_COUNT=2
        export GIT_CONFIG_KEY_0=credential.https://github.com.helper
        export GIT_CONFIG_VALUE_0=''
        export GIT_CONFIG_KEY_1=credential.https://github.com.helper
        export GIT_CONFIG_VALUE_1='!f() { if [ "$1" = get ]; then printf "username=x-access-token\npassword=%s\n" "$(cat /run/secrets/github_token)"; fi; }; f'
    fi
    GIT_TERMINAL_PROMPT=0 pnpm dlx mrs-developer missdev --no-config --fetch-https
EOT

RUN --mount=type=cache,id=pnpm,target=/app/.pnpm-store,uid=1000 <<EOT
    set -e
    pnpm install
    
    pnpm build

    # Remove test-only workspace package before production reinstall.
    # This package pulls @testing-library/jest-dom -> vitest peer, and cypress.
    rm -rf core/packages/volto-testing

    # pnpm prune is not reliable enough for monorepos; recreate node_modules instead.
    rm -rf node_modules

    pnpm install --prod --filter . --frozen-lockfile --config.confirmModulesPurge=false

    pnpm store prune

    rm -rf node_modules/.pnpm/babel-traverse@6.26.0 \
           node_modules/.pnpm/babel-plugin-transform-class-properties@6.24.1 \
           node_modules/.pnpm/babel-helper-function-name@6.24.1 \
           node_modules/.pnpm/babel-template@6.26.0 \
           node_modules/.pnpm/babel-types@6.26.0 \
           node_modules/.pnpm/babel-runtime@6.26.0
    rm -rf node_modules/.pnpm/simple-git@3.28.0
    rm -rf node_modules/.pnpm/basic-ftp@5.0.5
EOT

FROM ${PROD_CONFIG_IMAGE}

LABEL maintainer="PROCERGS <sites@procergs.rs.gov.br>" \
      org.label-schema.name="sitebase-frontend" \
      org.label-schema.description="Project Title frontend image." \
      org.label-schema.vendor="PROCERGS"

COPY --from=builder /app/ /app/
