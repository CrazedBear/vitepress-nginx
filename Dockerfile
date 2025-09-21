# 1) Build stage - install deps and build site
FROM node:20-bullseye AS build

WORKDIR /app

# Copy package files and install dependencies
COPY app/package.json app/package-lock.json* ./
RUN npm ci --silent || npm install --silent

# Copy app source and build (assumes a build script that outputs to `dist`)
COPY app/ ./
# Prefer docs:build (VitePress) then build, otherwise skip
RUN if [ -f package.json ] && grep -q "docs:build" package.json; then npm run docs:build; \
	elif [ -f package.json ] && grep -q "build" package.json; then npm run build; \
	else echo "No build script, skipping build"; fi

# Normalize build output into /app/www for easy copying in the final stage
RUN mkdir -p /app/www && \
	if [ -d /app/dist ]; then cp -a /app/dist/. /app/www/; \
	elif [ -d /app/docs/.vitepress/dist ]; then cp -a /app/docs/.vitepress/dist/. /app/www/; \
	elif [ -d /app/docs ]; then cp -a /app/docs/. /app/www/; \
	else cp -a /app/. /app/www/; fi

# 2) Production stage - nginx serving static files
FROM nginx:alpine

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Install curl for healthcheck
RUN apk add --no-cache curl

# Copy built assets from build stage. Try common VitePress output paths then fallback to `docs/` or the whole app.
COPY --from=build /app/www/ /usr/share/nginx/html/

# Add a custom nginx config with SPA fallback
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
	CMD curl -f http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]