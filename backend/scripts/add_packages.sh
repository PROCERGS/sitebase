#!/bin/bash
# Installs extra packages into the venv after the main mxdev install.
# Usage: add_packages.sh <uv_path> "pkg.one==1.0.0,git+https://github.com/org/pkg.two.git@1.0.0"
# Packages must be comma-separated pip requirement specifiers (PyPI or git URLs).

set -e

UV="${1:-uv}"
ADD_PACKAGES="${2:-}"

if [ -z "$ADD_PACKAGES" ]; then
    echo "add_packages.sh: ADD_PACKAGES is empty, nothing to do."
    exit 0
fi

echo "add_packages.sh: installing extra packages"

echo "$ADD_PACKAGES" | tr ',' '\n' | while IFS= read -r pkg; do
    pkg="$(echo "$pkg" | xargs)"  # trim whitespace
    [ -z "$pkg" ] && continue
    echo "  + $pkg"
    "$UV" pip install "$pkg"
done

echo "add_packages.sh: done."
