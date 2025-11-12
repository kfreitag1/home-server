#!/bin/bash
# Read password from file if COUCHDB_PASSWORD_FILE is set
if [ -n "$COUCHDB_PASSWORD_FILE" ] && [ -f "$COUCHDB_PASSWORD_FILE" ]; then
    export COUCHDB_PASSWORD=$(cat "$COUCHDB_PASSWORD_FILE")
fi

# Call the original entrypoint with all arguments
exec /docker-entrypoint.sh "$@"
