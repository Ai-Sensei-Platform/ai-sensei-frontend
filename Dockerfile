# syntax=docker/dockerfile:1

# ---- Build stage ----
FROM docker.io/library/node:22-alpine AS build
WORKDIR /app

# Backend URL is inlined into the bundle at build time by Vite
# (import.meta.env.VITE_API_BASE_URL). Pass with --build-arg.
ARG VITE_API_BASE_URL
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

# ---- Runtime stage ----
FROM docker.io/library/nginx:1.27-alpine AS runtime

# Cloud Run sends traffic to $PORT (default 8080); nginx must listen there.
COPY nginx.conf /etc/nginx/templates/default.conf.template
ENV PORT=8080

COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 8080
# nginx:alpine's entrypoint runs envsubst over /etc/nginx/templates/*.template,
# then launches nginx in the foreground.
CMD ["nginx", "-g", "daemon off;"]
