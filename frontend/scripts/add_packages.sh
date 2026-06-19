#!/bin/bash
# Injects extra npm packages into package.json dependencies before pnpm install.
# Usage: add_packages.sh "@scope/pkg@1.0.0,another-pkg@2.0.0"
# Packages must be comma-separated npm specifiers: name@version.
# If a package name is provided without a version and it already exists in package.json,
# its current pinned version is preserved.

set -e

ADD_PACKAGES="${1:-}"

if [ -z "$ADD_PACKAGES" ]; then
    echo "add_packages.sh: ADD_PACKAGES is empty, nothing to do."
    exit 0
fi

echo "add_packages.sh: injecting packages into package.json"

echo "$ADD_PACKAGES" | tr ',' '\n' | while IFS= read -r pkg; do
    pkg="$(echo "$pkg" | xargs)"  # trim whitespace
    [ -z "$pkg" ] && continue

    # Parse name and version, handling scoped packages (@scope/name@version)
    if [[ "$pkg" =~ ^(@[^@]+)@(.+)$ ]]; then
        name="${BASH_REMATCH[1]}"
        version="${BASH_REMATCH[2]}"
    elif [[ "$pkg" =~ ^([^@]+)@(.+)$ ]]; then
        name="${BASH_REMATCH[1]}"
        version="${BASH_REMATCH[2]}"
    else
        name="$pkg"
        version=""
    fi

    if [ -n "$version" ]; then
        echo "  + ${name}@${version}"
    else
        echo "  + ${name} (no version provided)"
    fi

    export _PKG_NAME="$name"
    export _PKG_VERSION="$version"
    python3 << 'PYEOF'
import json
import os

name = os.environ['_PKG_NAME']
version = os.environ['_PKG_VERSION']

with open('package.json') as f:
    data = json.load(f)

deps = data.setdefault('dependencies', {})
if version:
    deps[name] = version
    print(f'    set {name} -> {version}')
elif name in deps and deps[name]:
    print(f'    keeping existing version for {name}: {deps[name]}')
else:
    deps[name] = '*'
    print(f'    set {name} -> *')

with open('package.json', 'w') as f:
    json.dump(data, f, indent=2)
PYEOF
done

echo "add_packages.sh: done."
