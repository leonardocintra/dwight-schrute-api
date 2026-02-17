# 🛒 Plano de Arquitetura — Backend NestJS para E-commerce

**Dropshipping de Camisetas de Times | Multi-Frontend**
Stack: NestJS · PostgreSQL · Prisma 7 · Node.js
Versão 1.0

---

## Sumário

1. [Visão Geral e Objetivos](#1-visão-geral-e-objetivos)
2. [Análise de Plataformas de Pagamento](#2-análise-de-plataformas-de-pagamento)
3. [Arquitetura Recomendada](#3-arquitetura-recomendada)
4. [Módulos e Serviços NestJS](#4-módulos-e-serviços-nestjs)
5. [Banco de Dados — Schema Prisma](#5-banco-de-dados--schema-prisma)
6. [Estratégia Multi-Frontend](#6-estratégia-multi-frontend)
7. [Infraestrutura e DevOps](#7-infraestrutura-e-devops)
8. [Roadmap de Desenvolvimento](#8-roadmap-de-desenvolvimento)
9. [Conclusões e Próximos Passos](#9-conclusões-e-próximos-passos)

---

## 1. Visão Geral e Objetivos

Este documento define o plano de arquitetura para um backend robusto, escalável e reutilizável em múltiplos frontends de e-commerce, com foco inicial em dropshipping de camisetas de times de futebol.

### 1.1 Princípios de Design

- **API-First:** toda lógica de negócio exposta via REST API versionada (`/api/v1/...`)
- **Multi-Tenant Ready:** suporte a múltiplas lojas/frontends no mesmo backend
- **Stateless:** autenticação via JWT para escalar horizontalmente
- **Clean Architecture:** separação clara entre Controllers, Services e Repositories
- **Domain-Driven:** módulos organizados por domínio de negócio

### 1.2 Contexto do Negócio

Modelo: **Dropshipping** — sem estoque próprio, pedidos repassados ao fornecedor.

- Foco inicial: camisetas de times de futebol (brasileiros e internacionais)
- Frontends planejados: Web (Next.js/React), Mobile (React Native), potencial White-Label
- Volume inicial estimado: pequeno-médio porte, com estrutura pronta para escalar

---

## 2. Análise de Plataformas de Pagamento

Foram pesquisadas as principais plataformas do mercado brasileiro em 2025, avaliando taxas, qualidade de documentação/API, suporte a métodos locais (Pix, Boleto) e SDKs para Node.js.

### 2.1 Comparativo de Plataformas

| Plataforma | Cartão Crédito | Pix | Boleto | SDK Node.js | Doc. API |
|---|---|---|---|---|---|
| **Pagar.me** ⭐ | 2,99% + variável | ✅ Sim | ✅ Sim | ✅ Oficial | ⭐⭐⭐⭐⭐ |
| **Mercado Pago** | 4,98% padrão | ✅ Sim | ✅ Sim | ✅ Oficial | ⭐⭐⭐⭐ |
| **Stripe** | 2,9% + R$ 0,30 | ✅ Sim | ✅ Sim | ✅ Melhor SDK | ⭐⭐⭐⭐⭐ |
| **PagSeguro** | 3,19% - 3,79% | ✅ Sim | ✅ Sim | ⚠️ Limitado | ⭐⭐⭐ |
| **Efí Bank** | 3,49% | ✅ 1,19% | ✅ Sim | ✅ Sim | ⭐⭐⭐⭐ |

> ⚠️ Taxas variam conforme volume mensal e negociação comercial.

### 2.2 Recomendação Principal: Pagar.me

O **Pagar.me** (Grupo Stone) é a recomendação principal pelos seguintes motivos:

- API REST moderna e muito bem documentada em [docs.pagar.me](https://docs.pagar.me)
- SDK oficial para Node.js ativamente mantido
- **Checkout Transparente** nativo — cliente nunca sai do site
- Suporte completo: Cartão de Crédito, Débito, Pix, Boleto
- Split de pagamento (útil para futuras expansões marketplace)
- Assinaturas e cobranças recorrentes
- Parte do Grupo Stone — solidez financeira e suporte técnico especializado
- Antifraude integrado

### 2.3 Recomendação Secundária: Mercado Pago

O **Mercado Pago** serve como gateway secundário/fallback pela alta confiança dos consumidores brasileiros. Sua integração com o ecossistema do Mercado Livre aumenta a conversão.

### 2.4 Estratégia de Abstração de Pagamentos

A arquitetura usará o **padrão Strategy/Provider** para pagamentos, permitindo trocar ou adicionar gateways sem alterar a lógica de negócio:

```
PaymentProvider (interface)
├── createPayment()
├── refund()
├── getStatus()
└── handleWebhook()

Implementações:
├── PagarmeProvider
├── MercadoPagoProvider
└── StripeProvider  (futuro)
```

Seleção via variável de ambiente ou configuração por loja.

---

## 3. Arquitetura Recomendada

### 3.1 Camadas da Aplicação

| Camada | Responsabilidade |
|---|---|
| **Controllers** | Recebem requisições HTTP, validam DTOs com class-validator, retornam responses padronizados |
| **Services** | Lógica de negócio, orquestração entre repositórios, chamadas a APIs externas |
| **Repositories** | Acesso ao banco de dados via Prisma 7 — queries, mutations, transactions |
| **Guards** | Autenticação JWT, autorização por roles (ADMIN, CUSTOMER, STORE_OWNER) |
| **Interceptors** | Logging, transformação de responses, cache, rate limiting |
| **Middlewares** | CORS configurável por frontend, Helmet, compressão |

### 3.2 Stack Tecnológica Completa

| Categoria | Tecnologia |
|---|---|
| Runtime | Node.js 20 LTS |
| Framework | NestJS 10+ |
| Linguagem | TypeScript 5 |
| ORM | Prisma 7 |
| Banco de Dados | PostgreSQL 15+ |
| Autenticação | JWT + Refresh Tokens + bcrypt |
| Validação | class-validator + class-transformer |
| Documentação API | Swagger/OpenAPI (@nestjs/swagger) |
| Cache | Redis (@nestjs/cache-manager) |
| Filas/Jobs | Bull Queue |
| Upload de arquivos | AWS S3 ou Cloudflare R2 |
| Email | Nodemailer + Handlebars |
| Testes | Jest + Supertest |
| Containers | Docker + Docker Compose |

---

## 4. Módulos e Serviços NestJS

### 4.1 AuthModule — Autenticação e Autorização

| Arquivo | Descrição |
|---|---|
| `auth.module.ts` | Configuração JWT, Passport strategies (local, jwt, refresh) |
| `auth.service.ts` | `login()`, `register()`, `refreshToken()`, `logout()`, `forgotPassword()`, `resetPassword()` |
| `auth.controller.ts` | `POST /auth/login` · `POST /auth/register` · `POST /auth/refresh` · `POST /auth/logout` |
| `jwt.strategy.ts` | Validação do access token JWT |
| `roles.guard.ts` | Controle de acesso por perfil: ADMIN, CUSTOMER, STORE_MANAGER |

---

### 4.2 UsersModule — Clientes / Usuários

| Arquivo | Descrição |
|---|---|
| `users.service.ts` | CRUD de usuários, gerenciamento de endereços, histórico de pedidos |
| `users.controller.ts` | `GET /users/me` · `PUT /users/me` · `GET /users/me/orders` |
| `addresses.service.ts` | Múltiplos endereços por cliente (padrão, entrega, cobrança) |

---

### 4.3 ProductsModule — Catálogo de Produtos

| Arquivo | Descrição |
|---|---|
| `products.service.ts` | CRUD produtos, variantes (tamanho, cor/time), preços, imagens |
| `products.controller.ts` | `GET /products` · `GET /products/:id` · `POST /products` (admin) |
| `categories.service.ts` | Categorias hierárquicas (ex: Futebol > Série A > Flamengo) |
| `variants.service.ts` | Variantes: tamanho (P, M, G, GG), time/estampa, cor |
| `search.service.ts` | Busca com filtros: categoria, time, faixa de preço, disponibilidade |

---

### 4.4 OrdersModule — Pedidos

| Arquivo | Descrição |
|---|---|
| `orders.service.ts` | Criação, atualização de status, cálculo de totais |
| `orders.controller.ts` | `POST /orders` · `GET /orders/:id` · `PATCH /orders/:id/status` |
| `order-status.enum.ts` | `PENDING → PAYMENT_CONFIRMED → PROCESSING → SHIPPED → DELIVERED → CANCELLED` |
| `dropship.service.ts` | Repasse automático do pedido ao fornecedor via API/webhook |

---

### 4.5 PaymentsModule — Pagamentos

| Arquivo | Descrição |
|---|---|
| `payments.service.ts` | Orquestra provedores, cria transações, processa webhooks, gerencia reembolsos |
| `pagarme.provider.ts` | Integração Pagar.me: cartão, pix, boleto, checkout transparente |
| `mercadopago.provider.ts` | Integração Mercado Pago como gateway secundário/fallback |
| `payment.interface.ts` | Interface `IPaymentProvider` com: `createPayment`, `refund`, `getStatus`, `handleWebhook` |
| `webhook.controller.ts` | `POST /payments/webhook/pagarme` · `POST /payments/webhook/mercadopago` |
| `pix.service.ts` | Geração de QR Code Pix, controle de expiração, polling de status |

---

### 4.6 CartModule — Carrinho de Compras

| Arquivo | Descrição |
|---|---|
| `cart.service.ts` | Adicionar/remover itens, atualizar quantidades, aplicar cupons |
| `cart.controller.ts` | `GET /cart` · `POST /cart/items` · `PUT /cart/items/:id` · `DELETE /cart/items/:id` |
| `cart.strategy.ts` | Redis (sessão anônima) + DB (usuário logado), com merge no login |

---

### 4.7 ShippingModule — Frete e Entrega

| Arquivo | Descrição |
|---|---|
| `shipping.service.ts` | Cotação de frete, cálculo de prazo de entrega |
| `correios.provider.ts` | Integração API Correios (PAC, SEDEX) |
| `melhor-envio.provider.ts` | Integração Melhor Envio para múltiplas transportadoras |
| `tracking.service.ts` | Rastreamento e atualização automática de status via webhook |

---

### 4.8 CouponsModule — Cupons e Promoções

- Tipos: desconto percentual, valor fixo, frete grátis
- Regras: uso único, por usuário, por produto/categoria, validade
- Endpoints: `POST /coupons/apply` · `GET /coupons` (admin) · `POST /coupons` (admin)

---

### 4.9 NotificationsModule — Notificações

- Email transacional: confirmação de pedido, envio, entrega, cancelamento
- Templates HTML via Handlebars
- Filas de envio com Bull Queue (evita bloqueio da thread principal)
- Futuro: push notifications, WhatsApp Business API

---

### 4.10 StoresModule — Multi-Loja (Multi-Frontend)

- Cada frontend/loja tem um `Store` com configurações próprias
- Configurações: tema, domínio, gateway preferido, logo, CORS
- Middleware de resolução de loja via header `X-Store-Id` ou subdomain
- Preços e catálogos podem variar por loja

---

### 4.11 AdminModule — Painel Administrativo

- Dashboard: relatórios de vendas, produtos mais vendidos, taxa de conversão
- Gestão de pedidos: filtros, status em lote, exportação CSV
- Gestão de produtos, categorias, usuários e permissões
- Configurações de frete, gateway e notificações

---

### 4.12 Módulos de Infraestrutura

| Módulo | Responsabilidade |
|---|---|
| `DatabaseModule` | Configuração Prisma 7 com connection pooling (`PrismaService` global) |
| `CacheModule` | Redis para carrinho, sessions, rate limiting |
| `QueueModule` | Bull Queue para jobs assíncronos (emails, sincronização dropshipping) |
| `ConfigModule` | Variáveis de ambiente com validação via Joi schema |
| `LoggerModule` | Structured logging com Winston ou Pino |
| `HealthModule` | Health checks em `/health` (banco, Redis, gateways) |

---

## 5. Banco de Dados — Schema Prisma

### 5.1 Entidades Principais

| Model | Campos Principais | Relacionamentos |
|---|---|---|
| `User` | id, email, passwordHash, role, isActive, createdAt | → Address[], Order[], Cart, RefreshToken[] |
| `Store` | id, name, domain, slug, settings (Json), isActive | → Product[], Order[], StoreConfig |
| `Product` | id, name, description, basePrice, images, isActive, slug | → ProductVariant[], Category, Store |
| `ProductVariant` | id, size, color, teamName, sku, price, stockQty | → Product, OrderItem[], CartItem[] |
| `Category` | id, name, slug, parentId (self-relation), imageUrl | → Product[], Category (parent/children) |
| `Order` | id, status, totalAmount, subtotal, shippingCost, externalRef | → User, Store, OrderItem[], Payment, Address |
| `OrderItem` | id, quantity, unitPrice, totalPrice, snapshot (Json) | → Order, ProductVariant |
| `Payment` | id, provider, status, method, amount, gatewayId, pixCode, boletoUrl | → Order |
| `Cart` | id, sessionId (anon), expiresAt | → User?, CartItem[], Coupon? |
| `Coupon` | id, code, type, value, minOrderValue, usageLimit, expiresAt | → Order[], Store |
| `Address` | id, street, number, complement, city, state, zipCode, isDefault | → User, Order[] |

### 5.2 Boas Práticas com Prisma 7

- Usar `$transaction` para operações de pedido + pagamento atômicas
- Soft delete via campo `deletedAt` em entidades críticas (User, Product, Order)
- Índices otimizados: `email (unique)`, `slug`, `status` dos pedidos, `storeId`
- Migrations versionadas com `prisma migrate dev`
- Seeds separados para desenvolvimento e demonstração
- Usar `prisma.$extends` para middleware de auditoria (log de quem criou/atualizou)

---

## 6. Estratégia Multi-Frontend

### 6.1 Como Múltiplos Frontends Compartilham a API

- **Identificação de loja:** via header `X-Store-Id` em todas as requisições
- **CORS configurável:** origens permitidas por loja no banco de dados
- **Configurações do tema:** frontend busca via `GET /stores/config`
- **Catálogo:** compartilhado com preços diferentes por loja, ou catálogos independentes
- **Domínio próprio:** resolução automática de `storeId` via hostname

### 6.2 Frontends Planejados

| Frontend | Tech | Observação |
|---|---|---|
| Loja Principal | Next.js | SSR para SEO, checkout completo |
| App Mobile | React Native | Mesmo backend, experiência mobile-first |
| Painel Admin | React SPA | Gestão de pedidos, produtos, relatórios |
| White-Label | Qualquer | Clonar configurações para novas marcas |

### 6.3 Versionamento de API

- Endpoint base: `/api/v1/`
- Versionamento via URI (mais simples, compatível com qualquer cliente)
- Breaking changes criam `/api/v2/` mantendo v1 ativa por período de transição
- Documentação Swagger em `/api/docs` (protegida em produção)

---

## 7. Infraestrutura e DevOps

### 7.1 Ambiente de Desenvolvimento

- **Docker Compose:** NestJS + PostgreSQL + Redis rodando localmente com um comando
- Hot-reload com `ts-node-dev` em desenvolvimento
- `.env` separado por ambiente: `.env.development`, `.env.test`, `.env.production`
- Prisma Studio para visualizar dados durante desenvolvimento

### 7.2 Segurança

- **Rate limiting:** throttler por IP e por usuário (`NestJS ThrottlerModule`)
- **Helmet:** headers de segurança HTTP
- **CORS restritivo:** somente origens cadastradas por loja
- **Validação de entrada:** class-validator em todos os DTOs
- **SQL Injection:** Prisma usa prepared statements por padrão
- **Senhas:** bcrypt com rounds=12
- **Webhooks assinados:** validação de assinatura HMAC dos gateways de pagamento

### 7.3 Performance

- Cache Redis: produtos, configurações de loja, sessões de carrinho
- Paginação em todos os endpoints de listagem (cursor-based para grandes volumes)
- `select` apenas campos necessários no Prisma (evitar overfetch)
- Compressão gzip nas respostas
- Bull Queue: operações lentas (email, repasse dropshipping) em background

---

## 8. Roadmap de Desenvolvimento

| Fase | Duração | Entregáveis |
|---|---|---|
| **Fase 1** | Semanas 1-2 | Setup projeto NestJS, Docker, Prisma, PostgreSQL, `AuthModule` (JWT + refresh tokens) |
| **Fase 2** | Semanas 3-4 | `UsersModule`, `ProductsModule` (com variantes), `CategoriesModule`, upload de imagens |
| **Fase 3** | Semanas 5-6 | `CartModule`, `CouponsModule`, `ShippingModule` (Correios + Melhor Envio) |
| **Fase 4** | Semanas 7-9 | `PaymentsModule` completo: Pagar.me (cartão + pix + boleto), webhooks, `OrdersModule` |
| **Fase 5** | Semanas 10-11 | `NotificationsModule` (email), `DropshippingModule` (repasse de pedidos), `AdminModule` |
| **Fase 6** | Semanas 12-13 | `StoresModule` multi-loja, ajustes de CORS, documentação Swagger completa |
| **Fase 7** | Semanas 14-15 | Testes (Jest + E2E), performance, Redis cache, rate limiting, deploy Docker |

---

## 9. Conclusões e Próximos Passos

### 9.1 Decisões Finais Recomendadas

- **Gateway primário:** Pagar.me — melhor documentação API, SDK Node.js oficial, taxas negociáveis com volume
- **Gateway secundário:** Mercado Pago — alta confiança do consumidor BR, fallback seguro
- **Abstração via `IPaymentProvider`** — fácil adição de novos gateways sem alterar lógica de negócio
- **Prisma 7 + PostgreSQL** — maturidade, performance, type-safety total com TypeScript
- **Redis obrigatório** — carrinho, cache, filas (Bull) e rate limiting
- **Estrutura multi-store desde o início** — evita refatoração futura custosa

### 9.2 Primeiros Passos para Iniciar o Projeto

1. Criar repositório Git com estrutura monorepo (`apps/api`, `apps/admin`, `packages/shared`)
2. Configurar `docker-compose.yml` com PostgreSQL + Redis + NestJS
3. Criar schema Prisma base com as entidades definidas na Seção 5
4. Implementar `AuthModule` como fundação de toda a API
5. Criar conta de teste no Pagar.me (sandbox gratuito)
6. Configurar CI/CD básico (GitHub Actions: lint + testes + build)

### 9.3 Pontos de Atenção

- **LGPD:** dados pessoais dos clientes precisam de política de privacidade e possibilidade de exclusão
- **Chargebacks:** implementar análise de risco e antifraude desde o início
- **Licenciamento:** verificar direitos de imagem das camisetas de times antes de vender
- **Escalabilidade:** projetar para múltiplas instâncias NestJS sem estado compartilhado em memória local

---

*Documento gerado como base de planejamento técnico. Arquitetura sujeita a ajustes conforme evolução dos requisitos de negócio.*