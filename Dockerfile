# Statyczna strona mateuszkielbasa.dev serwowana przez nginx (bez roota, port 8080).
# Obraz budowany w GitHub Actions (.github/workflows/docker.yml) i publikowany w GHCR.
FROM nginxinc/nginx-unprivileged:1.27-alpine AS site
USER root
# Wszystko poza plikami z .dockerignore (index.html, a w przyszłości favicon, obrazki, /poradnik/...)
COPY . /site/
RUN rm -rf /site/deploy

FROM nginxinc/nginx-unprivileged:1.27-alpine
ENV NGINX_ENTRYPOINT_QUIET_LOGS=1
COPY deploy/docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=site /site/ /usr/share/nginx/html/

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD wget -qO- http://127.0.0.1:8080/healthz >/dev/null || exit 1
