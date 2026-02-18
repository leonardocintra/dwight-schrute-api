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

# Verificar se o arquivo existe
if [ ! -f "dist/src/main.js" ]; then
  echo "❌ ERROR: dist/src/main.js not found!"
  echo "📁 Listing dist directory:"
  ls -la dist/ || echo "dist/ directory does not exist"
  exit 1
fi

# Iniciar aplicação
echo "🎯 Starting NestJS application..."
exec node dist/src/main.js.js
