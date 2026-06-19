#!/bin/bash
# Thin wrapper around the official Plone docker-entrypoint.sh.
# Generates /app/inituser from $ADMIN_PASSWORD before delegating.
# inituser is only relevant on the very first start of a new site (empty ZODB).
# Zope ignores it once the admin user already exists in the database.
#
# Note: inituser uses SSHA (SHA1) because that is the only format Zope's
# User Folder supports — this is a Zope constraint, not a choice.
set -e

if [ -n "$ADMIN_PASSWORD" ]; then
    python3 - <<'EOF'
import base64, hashlib, os, sys
pw = os.environ["ADMIN_PASSWORD"]
salt = os.urandom(8)
digest = hashlib.sha1(pw.encode() + salt).digest()
ssha = base64.b64encode(digest + salt).decode()
path = "/app/inituser"
# Create with 600 atomically — avoids a world-readable window between open() and chmod()
fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
with os.fdopen(fd, "w") as f:
    f.write("admin:{SSHA}" + ssha)
print("sitebase-entrypoint: inituser generated from ADMIN_PASSWORD", file=sys.stderr)
EOF
    # Unset so the plaintext password is not visible in Zope's /proc/<pid>/environ
    unset ADMIN_PASSWORD
fi

exec /app/docker-entrypoint.sh "$@"
