# React Hello World - multi-stage build
# stage 1: install dependencies and build the static bundle
FROM node:20-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build          # output goes to /app/dist

# stage 2: serve the built files with nginx (no node in the final image)
FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
