FROM oven/bun:1-alpine

# Install OpenSSL for Prisma engine support on Alpine
RUN apk add --no-cache openssl ca-certificates

WORKDIR /app

# Copy dependency specifications
COPY package.json bun.lock* ./

# Install dependencies
RUN bun install --frozen-lockfile

# Copy Prisma schema and generate client
COPY prisma ./prisma/
RUN bunx prisma generate

# Copy source code and config
COPY tsconfig.json ./
COPY src ./src/

# Create uploads directory
RUN mkdir -p uploads

# Copy entrypoint script
COPY docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["./docker-entrypoint.sh"]
