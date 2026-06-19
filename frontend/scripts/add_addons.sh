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
    export _ADDON_NAME="$addon"
    node << 'NODEEOF'
const fs = require('fs');

const addon = process.env._ADDON_NAME;
let content = fs.readFileSync('volto.config.js', 'utf8');

const addonsPattern = /(const addons = \[)([\s\S]*?)(\n\];)/m;
const match = content.match(addonsPattern);
if (!match) {
  console.error('add_addons.sh: could not find addons array in volto.config.js');
  process.exit(1);
}

const [, opening, body, closing] = match;
const addons = [];
const seen = new Set();
const existingAddonPattern = /(['"])([^'"\n]+)\1/g;
let existingMatch;
while ((existingMatch = existingAddonPattern.exec(body)) !== null) {
  const existingAddon = existingMatch[2].trim();
  if (!existingAddon || seen.has(existingAddon)) continue;
  seen.add(existingAddon);
  addons.push(existingAddon);
}

if (seen.has(addon)) {
  console.log(`  = ${addon} (already present)`);
} else {
  console.log(`  + ${addon}`);
  addons.push(addon);
}

const normalizedBody = addons.length ? `\n  '${addons.join("',\n  '")}'` : '';
content = content.replace(addonsPattern, `${opening}${normalizedBody}${closing}`);
fs.writeFileSync('volto.config.js', content);
NODEEOF
done

node --check volto.config.js && echo "add_addons.sh: volto.config.js is valid."
echo "add_addons.sh: done."
