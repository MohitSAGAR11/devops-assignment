# Nginx Hello World
FROM nginx:1.27-alpine

# our own site config replaces the default one
COPY default.conf /etc/nginx/conf.d/default.conf
COPY index.html   /usr/share/nginx/html/index.html

EXPOSE 80
# the base image already runs: nginx -g "daemon off;"
