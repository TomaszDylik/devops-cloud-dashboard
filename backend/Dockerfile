# BUILD: Kompilacja projektu Maven i uruchomienie testow
FROM eclipse-temurin:21-jdk-alpine AS build

ARG BUILD_DATE
ARG VERSION

WORKDIR /app

# Kopiujemy pom.xml osobno zeby Docker cache'owal zaleznosci
COPY pom.xml .
RUN apk add --no-cache maven \
    && mvn dependency:go-offline -B

COPY src ./src
RUN mvn package -B

# TEST: Etap weryfikacji – testy uruchamiane podczas mvn package (surefire)
# Jesli testy nie przejda, build upadnie automatycznie.

# PRODUCTION: Minimalny obraz z JRE
FROM eclipse-temurin:21-jre-alpine AS production

ARG BUILD_DATE
ARG VERSION

LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.title="devops-cloud-dashboard-backend"

WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

# Katalog na logi aplikacji (montowany jako named volume w uruchomieniu)
RUN mkdir -p /app/logs && adduser -D appuser && chown appuser:appuser /app/logs

USER appuser

EXPOSE 3000

ENTRYPOINT ["java", "-jar", "app.jar"]

# Sprawdzanie co 30s czy endpoint /health odpowiada poprawnie
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "index.js"]
