# 战国卡牌联机服务端

基于 Railway + PostgreSQL + Redis 的联机对战后端服务。

## 技术栈

- **运行时**: Node.js 18+
- **框架**: Nitro (支持 WebSocket)
- **数据库**: PostgreSQL (玩家数据、战绩)
- **缓存**: Redis (匹配队列、游戏状态)
- **ORM**: Prisma

## 快速开始

### 1. 安装依赖

```bash
cd server
npm install
```

### 2. 配置环境变量

```bash
# Railway 控制台配置
DATABASE_URL="postgresql://user:password@host:5432/warring_states_card"
REDIS_URL="redis://host:6379"
JWT_SECRET="your-secret-key"
SUPPORT_ADMIN_KEY="客服后台查询工单用的密钥"
```

### 3. 初始化数据库

```bash
npm run db:push
```

### 4. 启动开发服务器

```bash
npm run dev
```

## API 接口

### 认证

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | `/api/auth/guest` | 游客登录 |

### 玩家

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | `/api/player/:odID` | 获取玩家信息 |
| POST | `/api/player/update-stats` | 更新战绩 |

### 匹配

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | `/api/match/join` | 加入匹配队列 |
| POST | `/api/match/leave` | 离开匹配队列 |
| POST | `/api/match/check` | 检查匹配状态 |

### 排行榜

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | `/api/leaderboard` | 获取排行榜 |

### 客服工单

| 方法 | 路径 | 描述 |
|------|------|------|
| POST | `/api/support/tickets` | 用户提交反馈（需登录 token；服务端自动附带玩家信息 + 近30天订单流水快照） |
| GET | `/api/support/tickets?status=open` | 客服后台拉取工单（需 `x-admin-key: <SUPPORT_ADMIN_KEY>` 或 `?key=`） |
| POST | `/api/support/tickets/:id/close` | 客服关闭工单（同上鉴权） |

### WebSocket

| 消息类型 | 描述 |
|------|------|
| `join` | 加入游戏房间 |
| `leave` | 离开游戏 |
| `action` | 发送游戏动作 |
| `sync` | 同步游戏状态 |
| `ping` | 心跳检测 |

## Railway 部署

### 1. 创建 Railway 项目

```bash
railway init
railway add postgresql
railway add redis
```

### 2. 设置环境变量

在 Railway 控制台设置:
- `DATABASE_URL` - PostgreSQL 连接字符串
- `REDIS_URL` - Redis 连接字符串
- `JWT_SECRET` - JWT 密钥
- `SUPPORT_ADMIN_KEY` - 客服后台查看工单的管理密钥

### 3. 部署

```bash
railway deploy
```

## 数据模型

### Player
- odID: 玩家ID (设备ID)
- odName: 玩家名称
- rating: ELO积分
- totalMatches: 总场次
- winCount: 胜场数

### Match
- odID: 玩家ID
- won: 是否胜利
- ratingChange: 积分变化
- duration: 对战时长

## 安全

- JWT Token 认证
- CORS 配置
- 输入验证
- SQL 注入防护 (Prisma ORM)

## 扩展

- 可添加排行榜、好友系统、公会系统
- 支持移动端推送通知
- 支持观战功能
