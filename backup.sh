#!/bin/bash
# Backup harian Postgres, simpan 14 hari terakhir. Pasang di VPS:
#   0 2 * * * /opt/toko-susilawati/backup.sh
set -e
DIR=/opt/toko-susilawati/backups
mkdir -p "$DIR"
docker exec toko-susilawati-postgres pg_dump -U postgres toko_susilawati | gzip > "$DIR/db-$(date +%F).sql.gz"
find "$DIR" -name 'db-*.sql.gz' -mtime +14 -delete
