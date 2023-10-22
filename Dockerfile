# Step 1 - Build
FROM node:18 AS builder
WORKDIR /app

# Install the Gatsby CLI globally
RUN npm install -g gatsby-cli

# Copy package.json and package-lock.json and install dependencies
COPY package*.json ./
RUN npm install -f

# Copy the rest of your app's source code
COPY . ./

# Build the Gatsby app
RUN gatsby build

# Step 2 - Serve
FROM gatsbyjs/gatsby:latest
COPY --from=builder /app/public /pub

# Expose the port
EXPOSE 80

CMD ["gatsby", "serve", "-H", "0.0.0.0", "-p", "80"]
