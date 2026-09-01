# Single-stage version of the SAME app, for size comparison only.
# Everything - dev dependencies, source, npm cache - stays in the final image.
FROM node:24-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
