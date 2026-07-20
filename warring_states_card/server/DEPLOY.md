# Railway 部署指南

## 当前状态

✅ Railway项目已创建: `warring-states-card-server`
✅ PostgreSQL数据库已创建
✅ Prisma数据模型已同步到数据库
✅ app-server服务已创建

## 待完成（需要手动操作）

### 1. 在Railway网站设置环境变量

访问: https://railway.com/project/d30d62cd-dca9-4d9a-b857-d986679ec093

在app-server服务的Variables中添加:

```
DATABASE_URL=postgresql://postgres:QCgwYJrdxEMxiWMPpWppepUrNZbZJQrI@zephyr.proxy.rlwy.net:41714/railway
REDIS_URL=redis://redis.railway.internal:6379
JWT_SECRET=warring-states-2026-secret
NODE_ENV=production
```

### 2. 添加Redis服务

在Railway网站点击 "Add a Service" → "Database" → 选择 "Redis"

### 3. 部署应用

点击 app-server 服务的 "Deploy" 按钮

### 4. 获取API地址

部署成功后，运行:
```bash
railway domain --service app-server
```

## API地址（待获取）

部署完成后，API地址为: `https://app-server-production-xxxx.up.railway.app`

## 数据库表

已在Railway PostgreSQL中创建:
- Player (玩家)
- Deck (卡组)
- Match (对战记录)
- Quest (任务)
- DailyReward (每日奖励)
- Collection (收藏)
- Leaderboard (排行榜)

## 本地开发

```bash
cd server
npm install
DATABASE_URL="postgresql://..." npx prisma db push
npm run dev
```

## 测试API

```bash
# 游客登录
curl -X POST https://your-domain.up.railway.app/api/auth/guest \
  -H "Content-Type: application/json" \
  -d '{"deviceId": "test-device-123"}'
```