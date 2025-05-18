# ---- Base Node ----
FROM node:18-slim AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

# ---- Dependencies ----
FROM base AS deps
WORKDIR /usr/src/app

# Install Playwright dependencies
# Reference: https://playwright.dev/docs/docker
# Note: You might only need dependencies for chromium if that's the only browser you use.
# For a smaller image, you can specify only chromium: RUN npx playwright install-deps chromium
RUN apt-get update && apt-get install -y --no-install-recommends \
    libnss3 \
    libnspr4 \
    libdbus-glib-1-2 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    # Extra deps that might be needed for some environments or if using other browsers
    # libpangocairo-1.0-0 \
    # libpango-1.0-0 \
    # libcairo2 \
    # libx11-xcb1 \
    # libxcursor1 \
    # libxss1 \
    # libxtst6 \
    && rm -rf /var/lib/apt/lists/*

COPY package.json pnpm-lock.yaml* ./ 
RUN pnpm install --prod --frozen-lockfile

# ---- Build ----
# This stage is more relevant if you have a build step (e.g., TypeScript)
# For a simple JS app, it might be similar to the deps stage or could be skipped/merged.
FROM base AS build
WORKDIR /usr/src/app
COPY --from=deps /usr/src/app/node_modules ./node_modules
COPY . .
# If you had a build command, it would go here, e.g.:
# RUN pnpm run build

# ---- Runner ----
FROM base AS runner
WORKDIR /usr/src/app

ENV NODE_ENV production
# Set a default port, Coolify might override this with its own PORT environment variable
ENV PORT 3000

COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./package.json
COPY --from=build /usr/src/app/index.js ./index.js

# Download Playwright browsers. This ensures they are present in the final image.
# If you only use chromium, you can specify: RUN npx playwright install chromium
RUN npx playwright install --with-deps chromium

# Expose the port the app runs on
EXPOSE ${PORT}

# Set user to non-root for security
USER node

CMD [ "node", "index.js" ]