#!/bin/sh
set -e

echo "🚀 Starting Dwight Schrute API..."

# Verificar se DATABASE_URL está definida
if [ -z "$DATABASE_URL" ]; then
  echo "❌ ERROR: DATABASE_URL environment variable is not set!"
  exit 1
fi

echo "✅ DATABASE_URL is configured"

# Executar migrations
echo "📦 Running Prisma migrations..."
npx prisma migrate deploy

echo "✅ Migrations completed successfully"

# Iniciar aplicação
echo "🎯 Starting NestJS application..."
exec node dist/main
