#!/bin/bash
set -e

# Function to create a user if it doesn't exist
create_user_if_not_exists() {
  local user=$1
  local password=$2
  echo "Checking if user ${user} exists..."
  if psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${user}'" | grep -q 1; then
    echo "User ${user} already exists. Skipping creation."
  else
    echo "User ${user} does not exist. Creating..."
    psql -c "CREATE USER ${user} WITH PASSWORD '${password}';"
  fi
}

# Function to create a database if it doesn't exist
create_database_if_not_exists() {
  local db=$1
  local owner=$2
  echo "Checking if database ${db} exists..."
  if psql -lqt | cut -d \| -f 1 | grep -qw ${db}; then
    echo "Database ${db} already exists. Skipping creation."
  else
    echo "Database ${db} does not exist. Creating..."
    psql -c "CREATE DATABASE ${db} OWNER ${owner};"
  fi
}

# Main execution
create_user_if_not_exists 'dbadminuser' 'myP@ssw0rd'
create_database_if_not_exists 'blogdb' 'dbadminuser'

# Set privileges and configurations
psql -d blogdb -c "
  ALTER ROLE dbadminuser SET client_encoding TO 'utf8';
  ALTER ROLE dbadminuser SET default_transaction_isolation TO 'read committed';
  ALTER ROLE dbadminuser SET timezone TO 'UTC';
  GRANT ALL PRIVILEGES ON DATABASE blogdb TO dbadminuser;
  GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO dbadminuser;
  GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO dbadminuser;
  GRANT USAGE, CREATE ON SCHEMA public TO dbadminuser;
"

