#!/bin/bash
# Registers extra Volto addons in volto.config.js before pnpm install.
# Usage: add_addons.sh "@scope/addon,another-addon"
# Addons must be comma-separated list of Volto addon names (as registered in volto.config.js).

set -e

ADD_ADDONS="${1:-}"

if [ -z "$ADD_ADDONS" ]; then
    echo "add_addons.sh: ADD_ADDONS is empty, nothing to do."
    exit 0
fi

echo "add_addons.sh: registering addons in volto.config.js"

echo "$ADD_ADDONS" | tr ',' '\n' | while IFS= read -r addon; do
    addon="$(echo "$addon" | xargs)"  # trim whitespace
    [ -z "$addon" ] && continue
    echo "  + $addon"
    node -e "
const fs = require('fs');
const addon = '${addon}';
let content = fs.readFileSync('volto.config.js', 'utf8');
content = content.replace(/(const addons = \[[\s\S]*?)(\n\];)/, (match, body, closing) => {
    const trimmed = body.trimEnd();
    const needsComma = !trimmed.endsWith(',');
    return trimmed + (needsComma ? ',' : '') + \"\n  '\" + addon + \"'\" + closing;
});
fs.writeFileSync('volto.config.js', content);
"
done

node --check volto.config.js && echo "add_addons.sh: volto.config.js is valid."
echo "add_addons.sh: done."
