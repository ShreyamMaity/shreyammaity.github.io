# Step 1 - Build
FROM node:18 AS builder
WORKDIR /app

# Install the Gatsby CLI globally
RUN npm install -g gatsby-cli
# Copy package.json and package-lock.json and install dependencies
COPY . .
RUN npm install -f

# Rebuild sharp and pngquant
RUN npm rebuild sharp
RUN npm rebuild pngquant-bin

CMD ["npm", "start"]