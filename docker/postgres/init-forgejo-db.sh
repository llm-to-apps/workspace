#!/usr/bin/env bash
set -euo pipefail

forgejo_db="${FORGEJO_POSTGRES_DATABASE:-forgejo}"
forgejo_user="${FORGEJO_POSTGRES_USER:-forgejo}"
forgejo_password="${FORGEJO_POSTGRES_PASSWORD:-forgejo}"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
DO
\$do\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles WHERE rolname = '${forgejo_user}'
   ) THEN
      CREATE ROLE "${forgejo_user}" LOGIN PASSWORD '${forgejo_password}';
   END IF;
END
\$do\$;
SELECT 'CREATE DATABASE "${forgejo_db}" OWNER "${forgejo_user}"'
WHERE NOT EXISTS (
   SELECT FROM pg_database WHERE datname = '${forgejo_db}'
)\gexec
GRANT ALL PRIVILEGES ON DATABASE "${forgejo_db}" TO "${forgejo_user}";
EOSQL
