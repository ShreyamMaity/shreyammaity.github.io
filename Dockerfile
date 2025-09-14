# Step 1 - Build the application (using Debian-based image for better compatibility)
FROM node:16-bullseye AS builder
WORKDIR /app

# Install build dependencies for Debian
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    libvips-dev \
    autoconf \
    automake \
    libtool \
    nasm \
    pkg-config \
    libpng-dev \
    libjpeg-dev \
    && rm -rf /var/lib/apt/lists/*

# Yarn is already installed in the Node.js Debian image

# Configure npm for better reliability
RUN npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000 && \
    npm config set fetch-retries 3

# Install the Gatsby CLI globally (use latest compatible with Node 16)
RUN npm install -g gatsby-cli@4.25.0

# Copy package files and install dependencies with yarn (more reliable)
COPY package*.json yarn.lock ./
RUN yarn install --frozen-lockfile --network-timeout 300000

# Copy source code
COPY . .

# Create a Docker-specific gatsby-config.js without problematic plugins
RUN cp gatsby-config.js gatsby-config.js.backup && \
    sed -i 's/`gatsby-plugin-robots-txt`,//g' gatsby-config.js && \
    sed -i 's/`gatsby-plugin-offline`,//g' gatsby-config.js

# Rebuild sharp and pngquant for the container architecture
RUN npm rebuild sharp
RUN npm rebuild pngquant-bin

# Disable telemetry and build the static site
RUN npx gatsby telemetry --disable

# Set memory limits and disable problematic optimizations
ENV NODE_OPTIONS="--max-old-space-size=2048"
ENV GATSBY_CPU_COUNT=1
ENV GATSBY_PARALLEL_QUERY_CHUNK_SIZE=10
ENV CI=true

# Try building with Sharp disabled for image processing
RUN GATSBY_SHARP=false yarn build

# Step 2 - Serve the built application
FROM nginx:alpine
COPY --from=builder /app/public /usr/share/nginx/html

# Create custom nginx config for SPA routing
RUN echo 'server { \
    listen 3009; \
    server_name localhost; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 3009

CMD ["nginx", "-g", "daemon off;"]