# Node.js Hello World
FROM node:20-alpine

WORKDIR /app

# copy the manifests first so this layer is cached when only the code changes
COPY package*.json ./
RUN npm install --omit=dev

COPY server.js ./

EXPOSE 3000
CMD ["node", "server.js"]
