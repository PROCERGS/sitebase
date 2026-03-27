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
python3 << 'PYEOF'
import json, os, sys

try:
    new_entries = json.loads(os.environ['_MRS_NEW_ENTRIES'])
except json.JSONDecodeError as e:
    print(f'add_mrsdeveloper.sh: invalid JSON — {e}', file=sys.stderr)
    sys.exit(1)

with open('mrs.developer.json') as f:
    data = json.load(f)

data.update(new_entries)

with open('mrs.developer.json', 'w') as f:
    json.dump(data, f, indent=2)

print(f'  merged: {list(new_entries.keys())}')
PYEOF

echo "add_mrsdeveloper.sh: done."
