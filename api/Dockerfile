FROM oven/bun:alpine AS base

# Stage 1: Install dependencies
FROM base AS deps
WORKDIR /app
COPY package.json ./
RUN bun install --frozen-lockfile

WORKDIR /app
ENV NODE_ENV=production
COPY . .

USER bun
EXPOSE 3000

CMD ["bun", "run", "start"]