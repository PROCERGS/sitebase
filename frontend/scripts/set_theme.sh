#!/bin/bash
# Sets the Volto theme in volto.config.js before the build.
# Usage: set_theme.sh "@plone/volto-theme"
# The argument must be a valid npm package name of a Volto theme.

set -e

SET_THEME="${1:-}"

if [ -z "$SET_THEME" ]; then
    echo "set_theme.sh: SET_THEME is empty, nothing to do."
    exit 0
fi

echo "set_theme.sh: setting theme to '$SET_THEME' in volto.config.js"

export _THEME_NAME="$SET_THEME"
node -e "
const fs = require('fs');
const theme = process.env._THEME_NAME;
let content = fs.readFileSync('volto.config.js', 'utf8');
const pattern = /^const theme = .*;$/m;
if (!pattern.test(content)) {
    console.error('set_theme.sh: could not find theme line in volto.config.js');
    process.exit(1);
}
const updated = content.replace(pattern, \`const theme = '\${theme}';\`);
fs.writeFileSync('volto.config.js', updated);
console.log('  theme: ' + theme);
"

node --check volto.config.js && echo "set_theme.sh: volto.config.js is valid."
echo "set_theme.sh: done."
