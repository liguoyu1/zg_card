# 战国卡牌 Web 前端镜像 — 多阶段构建
# 阶段 1：在镜像内安装 Flutter SDK 并构建 web 产物
# 阶段 2：nginx 托管静态产物
#
# 本镜像供 Railway（GitHub 集成）/ Docker 直接构建，无需本机 flutter build。
# 如需本地自定义 API 地址，可在构建参数中传入：
#   docker build --build-arg API_BASE_URL=https://wscard.games --build-arg API_HOST=wscard.games .
FROM ghcr.io/cirruslabs/flutter:3.44.0 AS build
WORKDIR /app

# 复制 pubspec 依赖清单（利用构建缓存）
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# 复制全部源码
COPY . .
# 移除本地旧构建产物，避免混入
RUN rm -rf build

# 构建 web（无 dart-define 时 Flutter 用默认值；有则覆盖）
ARG API_BASE_URL
ARG API_HOST
# Xsolla Login 客户端参数（编译期注入，缺省则按钮/静默登录不可用）
ARG XSOLLA_CLIENT_ID=895277
ARG XSOLLA_PROJECT_ID=6db50f41-6a0a-4b9f-a033-8fd7bfaab372
RUN if [ -n "$API_BASE_URL" ]; then \
      flutter build web --release --wasm \
        --dart-define=API_BASE_URL=$API_BASE_URL \
        --dart-define=API_HOST=$API_HOST \
        --dart-define=XSOLLA_CLIENT_ID=$XSOLLA_CLIENT_ID \
        --dart-define=XSOLLA_PROJECT_ID=$XSOLLA_PROJECT_ID; \
    else \
      flutter build web --release --wasm \
        --dart-define=XSOLLA_CLIENT_ID=$XSOLLA_CLIENT_ID \
        --dart-define=XSOLLA_PROJECT_ID=$XSOLLA_PROJECT_ID; \
    fi

FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
COPY --from=build /app/build/web /usr/share/nginx/html
# 修正静态文件权限
RUN chmod -R a+r /usr/share/nginx/html
EXPOSE 80
CMD ["/entrypoint.sh"]
