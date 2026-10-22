# Étape 1 : dépendances de production, aux versions figées par package-lock.json
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Étape 2 : image d'exécution (Node.js 22 LTS sur Alpine), sans npm, npx, corepack ni yarn,
# inutiles pour faire tourner l'API et sources de vulnérabilités
FROM node:22-alpine
ENV NODE_ENV=production
WORKDIR /app
RUN rm -rf /usr/local/lib/node_modules /opt/yarn-* \
      /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/corepack /usr/local/bin/yarn /usr/local/bin/yarnpkg

COPY --from=deps /app/node_modules ./node_modules
COPY package.json index.js ./

# Exécution sans les droits root (UID 1000 = utilisateur "node" fourni par l'image)
USER 1000

EXPOSE 3000

# Sonde de santé du conteneur ; sur ECS, l'ALB vérifie en plus la route /
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD ["wget", "-qO", "/dev/null", "http://127.0.0.1:3000/"]

CMD ["node", "index.js"]
