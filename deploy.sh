#!/bin/bash
set -e

# ==============================================================================
# Script Otomasi Deploy SUSILAWATI TOKO ke VPS 187.77.154.107
# Domain: https://toko-susilawati.legaltechz.com
# ==============================================================================

VPS_HOST="root@187.77.154.107"
VPS_DIR="/opt/toko-susilawati"
LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 [1/5] Membangun Frontend Flutter Web release..."
cd "$LOCAL_DIR/mobile"
flutter build web --release

echo "📦 [2/5] Mengirim hasil build Web ke VPS..."
rsync -avz --delete "$LOCAL_DIR/mobile/build/web/" "$VPS_HOST:$VPS_DIR/mobile/build/web/"

echo "🔄 [3/5] Memperbarui kode di VPS..."
ssh "$VPS_HOST" "cd $VPS_DIR && git pull origin main"

echo "🐳 [4/5] Membangun & me-restart container Docker di VPS..."
ssh "$VPS_HOST" "cd $VPS_DIR && docker compose up -d --build"

echo "🔍 [5/5] Memverifikasi status API di produksi..."
sleep 3
HEALTH_STATUS=$(curl -s https://toko-susilawati.legaltechz.com/health)
echo "Hasil Health Check: $HEALTH_STATUS"

echo "✅ Deploy selesai! Akses web: https://toko-susilawati.legaltechz.com"
