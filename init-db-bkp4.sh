#!/bin/bash
set -e

# Create the database and user
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE blogdb;
    CREATE USER dbadminuser WITH PASSWORD 'myP@ssw0rd';
    ALTER ROLE dbadminuser SET client_encoding TO 'utf8';
    ALTER ROLE dbadminuser SET default_transaction_isolation TO 'read committed';
    ALTER ROLE dbadminuser SET timezone TO 'UTC';
    GRANT ALL PRIVILEGES ON DATABASE blogdb TO dbadminuser;
EOSQL

# Grant all privileges on the public schema to the user and set the owner
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "blogdb" <<-EOSQL
    REVOKE ALL ON SCHEMA public FROM PUBLIC;
    GRANT ALL PRIVILEGES ON SCHEMA public TO dbadminuser;
    ALTER SCHEMA public OWNER TO dbadminuser;
EOSQL

