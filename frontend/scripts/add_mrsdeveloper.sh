#!/bin/bash
# Merges extra entries into mrs.developer.json before mrs-developer runs.
# Usage: add_mrsdeveloper.sh '<json-object>'
# The argument must be a valid JSON object whose keys are package names.
# Example:
#   add_mrsdeveloper.sh '{"my-addon": {"url": "git@github.com:org/my-addon.git", "https": "https://github.com/org/my-addon.git", "tag": "1.0.0"}}'

set -e

ADD_MRSDEVELOPER="${1:-}"

if [ -z "$ADD_MRSDEVELOPER" ]; then
    echo "add_mrsdeveloper.sh: ADD_MRSDEVELOPER is empty, nothing to do."
    exit 0
fi

echo "add_mrsdeveloper.sh: merging entries into mrs.developer.json"

export _MRS_NEW_ENTRIES="$ADD_MRSDEVELOPER"
node << 'NODEEOF'
const fs = require('fs');

let newEntries;
try {
    newEntries = JSON.parse(process.env._MRS_NEW_ENTRIES);
} catch (e) {
    console.error(`add_mrsdeveloper.sh: invalid JSON — ${e.message}`);
    process.exit(1);
}

const data = JSON.parse(fs.readFileSync('mrs.developer.json', 'utf8'));
Object.assign(data, newEntries);
fs.writeFileSync('mrs.developer.json', JSON.stringify(data, null, 2) + '\n');
console.log(`  merged: ${Object.keys(newEntries).join(', ')}`);
NODEEOF

echo "add_mrsdeveloper.sh: done."
