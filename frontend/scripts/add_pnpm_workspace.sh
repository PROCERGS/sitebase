#!/bin/bash
# Appends extra workspace glob patterns to pnpm-workspace.yaml before pnpm install.
# Usage: add_pnpm_workspace.sh "packages/my-addon,src/another-package"
# The argument must be a comma-separated list of glob patterns (same format as pnpm-workspace.yaml entries).

set -e

ADD_PNPM_WORKSPACE="${1:-}"

if [ -z "$ADD_PNPM_WORKSPACE" ]; then
    echo "add_pnpm_workspace.sh: ADD_PNPM_WORKSPACE is empty, nothing to do."
    exit 0
fi

echo "add_pnpm_workspace.sh: adding workspaces to pnpm-workspace.yaml"

echo "$ADD_PNPM_WORKSPACE" | tr ',' '\n' | while IFS= read -r workspace; do
    workspace="$(echo "$workspace" | xargs)"  # trim whitespace
    [ -z "$workspace" ] && continue
    echo "  + $workspace"
    printf "  - '%s'\n" "$workspace" >> pnpm-workspace.yaml
done

echo "add_pnpm_workspace.sh: done."
