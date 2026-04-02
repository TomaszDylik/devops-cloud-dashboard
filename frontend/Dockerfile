# DEPS: Instalacja wszystkich zależności (w tym devDependencies potrzebnych do buildu)
FROM node:20-alpine AS deps

ARG BUILD_DATE
ARG VERSION
ARG NODE_ENV=production

WORKDIR /app

COPY package*.json ./
RUN npm install --include=dev

# BUILD: Kompilacja aplikacji React do statycznych plików HTML/CSS/JS
FROM node:20-alpine AS build

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build


# PRODUCTION: Minimalny obraz Nginx – kopiujemy TYLKO gotowy build, bez Node.js i kodu źródłowego
FROM nginx:1.27-alpine AS production

ARG BUILD_DATE
ARG VERSION
ARG NODE_ENV=production

LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.title="devops-cloud-dashboard-frontend"

COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

ENV NODE_ENV=$NODE_ENV

# Ustaw uprawnienia do katalogów nginx dla użytkownika "nginx" (nie root)
RUN chown -R nginx:nginx /usr/share/nginx/html \
  && chown -R nginx:nginx /var/cache/nginx \
  && chown -R nginx:nginx /var/log/nginx \
  && chown -R nginx:nginx /etc/nginx/conf.d \
  && touch /var/run/nginx.pid \
  && chown nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 8080

# Sprawdzanie co 30s czy Nginx serwuje stronę główną
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
