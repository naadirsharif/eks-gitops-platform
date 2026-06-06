# Stage 1: Build
FROM node:22 AS builder

WORKDIR /app

RUN npm install -g pnpm

COPY it-tools/ ./

RUN pnpm install && pnpm run build


# Stage 2: Runtime
FROM nginx:alpine AS runner

COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80
