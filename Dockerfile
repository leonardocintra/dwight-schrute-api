# Dockerfile para deploy no EasyPanel
# Node.js 22 - Build otimizado multi-stage

# Stage 1: Build
FROM node:22-alpine AS builder

# Atualizar npm para a versão mais recente
RUN npm install -g npm@latest

WORKDIR /app

# Copiar arquivos de dependências
COPY package*.json ./
COPY prisma ./prisma/

# Instalar dependências
RUN npm ci

# Copiar código fonte
COPY . .

# Gerar Prisma Client
RUN npx prisma generate

# Build da aplicação
RUN npm run build

# Stage 2: Production
FROM node:22-alpine AS production

# Atualizar npm para a versão mais recente
RUN npm install -g npm@latest

WORKDIR /app

# Instalar apenas dependências de produção
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copiar Prisma config e schema para gerar client
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/prisma.config.ts ./prisma.config.ts
RUN npx prisma generate

# Copiar build da aplicação
COPY --from=builder /app/dist ./dist

# Copiar script de entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Criar usuário não-root para segurança
RUN addgroup -g 1001 -S nodejs && \
  adduser -S nestjs -u 1001 && \
  chown -R nestjs:nodejs /app

USER nestjs

# Expor porta da aplicação
EXPOSE 3005

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3005/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Comando de inicialização
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/main"]
