# syntax=docker/dockerfile:1

# ---- Stage 1: Website bauen (Astro Starlight) ----
FROM node:22-alpine AS website
WORKDIR /build/website
COPY website/package.json website/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY website/ ./
RUN npm run build

# ---- Stage 2: Slides vorbereiten (reveal.js lokal einbetten) ----
FROM node:22-alpine AS slides
WORKDIR /build/slides
COPY slides/package.json slides/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY slides/ ./
RUN node build.mjs

# ---- Stage 3: Laufzeit (nginx ohne root) ----
FROM nginxinc/nginx-unprivileged:1.29-alpine AS runtime
COPY container/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=website /build/website/dist/ /usr/share/nginx/html/
COPY --from=slides  /build/slides/out/   /usr/share/nginx/html/slides/

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/healthz >/dev/null || exit 1
