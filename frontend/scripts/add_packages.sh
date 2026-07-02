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

export _ADD_PACKAGES="$ADD_PACKAGES"
node << 'NODEEOF'
const fs = require('fs');

const pkgs = process.env._ADD_PACKAGES.split(',').map(p => p.trim()).filter(Boolean);
const data = JSON.parse(fs.readFileSync('package.json', 'utf8'));
const deps = data.dependencies || (data.dependencies = {});

for (const pkg of pkgs) {
    let name, version;
    if (pkg.startsWith('@')) {
        // Scoped package: @scope/name@version — skip the leading @ when looking for @version
        const at = pkg.indexOf('@', 1);
        name = at === -1 ? pkg : pkg.slice(0, at);
        version = at === -1 ? '' : pkg.slice(at + 1);
    } else {
        const at = pkg.indexOf('@');
        name = at === -1 ? pkg : pkg.slice(0, at);
        version = at === -1 ? '' : pkg.slice(at + 1);
    }

    if (version) {
        console.log(`  + ${name}@${version}`);
        deps[name] = version;
    } else if (name in deps && deps[name]) {
        console.log(`  keeping existing version for ${name}: ${deps[name]}`);
    } else {
        console.log(`  + ${name} (no version, using *)`);
        deps[name] = '*';
    }
}

fs.writeFileSync('package.json', JSON.stringify(data, null, 2) + '\n');
NODEEOF

echo "add_packages.sh: done."
