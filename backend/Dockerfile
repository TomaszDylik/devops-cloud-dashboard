# DEPS: Instalacja wyłącznie zależności produkcyjnych (bez devDependencies)
FROM node:20-alpine AS deps

ARG BUILD_DATE
ARG VERSION
ARG NODE_ENV=production

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

# TEST: Instalacja devDependencies i uruchomienie testów jednostkowych
FROM deps AS test

WORKDIR /app

COPY . .
RUN npm install --include=dev
RUN npm test

# PRODUCTION: Minimalny obraz końcowy – kopiujemy tylko node_modules i kod aplikacji
FROM node:20-alpine AS production

ARG BUILD_DATE
ARG VERSION
ARG NODE_ENV=production

LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.title="devops-cloud-dashboard-backend"

WORKDIR /app

# Kopiowanie gotowego node_modules z etapu deps (bez devDependencies)
COPY --from=deps /app/node_modules ./node_modules

# Kopiowanie tylko plików aplikacji (bez Dockerfile, .dockerignore itp.)
COPY index.js ./
COPY package.json ./

# Katalog na logi aplikacji (montowany jako named volume w uruchomieniu)
RUN mkdir -p /app/logs && chown node:node /app/logs

ENV NODE_ENV=$NODE_ENV

USER node

EXPOSE 3000

# Sprawdzanie co 30s czy endpoint /health odpowiada poprawnie
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "index.js"]
