#!/bin/sh
set -e

echo "⏳ Running Prisma database migrations..."
bunx prisma migrate deploy

echo "🌱 Ensuring initial data / seeds exist..."
bun run src/seed.ts || echo "Seed executed or skipped"

echo "🚀 Starting SUSILAWATI TOKO Backend API..."
exec bun run src/index.ts
