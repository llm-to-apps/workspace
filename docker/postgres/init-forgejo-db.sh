#!/usr/bin/env bash
set -euo pipefail

forgejo_db="${FORGEJO_POSTGRES_DATABASE:-forgejo}"
forgejo_user="${FORGEJO_POSTGRES_USER:-forgejo}"
forgejo_password="${FORGEJO_POSTGRES_PASSWORD:-forgejo}"
seaweedfs_db="${SEAWEEDFS_POSTGRES_DATABASE:-seaweedfs}"
seaweedfs_user="${SEAWEEDFS_POSTGRES_USER:-seaweedfs}"
seaweedfs_password="${SEAWEEDFS_POSTGRES_PASSWORD:-seaweedfs}"

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

DO
\$do\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles WHERE rolname = '${seaweedfs_user}'
   ) THEN
      CREATE ROLE "${seaweedfs_user}" LOGIN PASSWORD '${seaweedfs_password}';
   END IF;
END
\$do\$;
SELECT 'CREATE DATABASE "${seaweedfs_db}" OWNER "${seaweedfs_user}"'
WHERE NOT EXISTS (
   SELECT FROM pg_database WHERE datname = '${seaweedfs_db}'
)\gexec
GRANT ALL PRIVILEGES ON DATABASE "${seaweedfs_db}" TO "${seaweedfs_user}";
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$seaweedfs_db" <<-EOSQL
CREATE TABLE IF NOT EXISTS filemeta (
  dirhash BIGINT,
  name VARCHAR(65535) COLLATE "C",
  directory VARCHAR(65535),
  meta bytea,
  PRIMARY KEY (dirhash, name)
);
ALTER TABLE filemeta
  ALTER COLUMN name TYPE VARCHAR(65535) COLLATE "C";
GRANT ALL PRIVILEGES ON TABLE filemeta TO "${seaweedfs_user}";
EOSQL
