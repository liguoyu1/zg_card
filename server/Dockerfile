# 战国卡牌联机服务端 — 本地/部署镜像
# 构建上下文为 ./server（见 docker-compose.yml）
# 构建阶段：安装依赖 + 生成 Prisma Client + 构建 Nitro 输出
FROM node:22-slim AS build
WORKDIR /app

# 安装 openssl（Prisma 需要）与 ca-certificates
RUN apt-get update && apt-get install -y --no-install-recommends openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./
RUN npm install --ignore-scripts

COPY . .
RUN npx prisma generate && npm run build

# 运行时阶段
FROM node:22-slim AS runtime
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 仅复制运行所需：Nitro 构建产物 + 运行时依赖 + Prisma schema
COPY --from=build /app/.output ./.output
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/prisma ./prisma

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

# 启动前同步数据库结构（幂等），再启动 Nitro 服务
# --accept-data-loss：公告等表结构演进时允许删列/改类型（本项目无关键留存要求）
CMD ["sh", "-c", "npx prisma db push --skip-generate --accept-data-loss && node .output/server/index.mjs"]
