#!/bin/bash
# Injects extra npm packages into package.json dependencies before pnpm install.
# Usage: add_packages.sh "@scope/pkg@1.0.0,another-pkg@2.0.0"
# Packages must be comma-separated npm specifiers: name@version (or name alone for latest).

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
        version="*"
    fi

    echo "  + ${name}@${version}"
    python3 -c "
import json
with open('package.json') as f:
    data = json.load(f)
data['dependencies']['${name}'] = '${version}'
with open('package.json', 'w') as f:
    json.dump(data, f, indent=2)
print('    package.json updated')
"
done

echo "add_packages.sh: done."
