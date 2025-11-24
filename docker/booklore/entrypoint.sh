#!/bin/sh
set -e

if [ -f /run/secrets/booklore-db-password ]; then
    export DATABASE_PASSWORD=$(cat /run/secrets/booklore-db-password)
fi

exec "$@"
