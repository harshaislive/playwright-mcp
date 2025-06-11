FROM node:22-bookworm-slim

ARG PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
ENV PLAYWRIGHT_BROWSERS_PATH=${PLAYWRIGHT_BROWSERS_PATH}
ENV NODE_ENV=production

# Set the working directory
WORKDIR /app

# Copy package files first for better caching
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci --omit=dev && \
    # Install system dependencies for playwright
    npx -y playwright-core install-deps chromium && \
    # Install Playwright browsers
    npx -y playwright-core install --no-shell chromium

# Copy source code and build files
COPY *.json *.js *.ts ./
COPY src/ ./src/

# Install dev dependencies and build
RUN npm ci && \
    npm run build && \
    # Clean up dev dependencies after build
    npm prune --production

# Create non-root user for security
RUN groupadd -r nodeuser && useradd -r -g nodeuser nodeuser
RUN chown -R nodeuser:nodeuser /app
USER nodeuser

# Expose the port (Railway will handle port mapping)
EXPOSE 8931

# Run in headless mode with chromium
ENTRYPOINT ["node", "cli.js", "--headless", "--browser", "chromium", "--no-sandbox", "--port", "8931"]
