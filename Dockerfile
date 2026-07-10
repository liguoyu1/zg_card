FROM ghcr.io/cirruslabs/flutter:3.27.1 AS build
WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --release --web-renderer canvaskit

FROM nginx:alpine AS runtime
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 80
CMD ["/entrypoint.sh"]