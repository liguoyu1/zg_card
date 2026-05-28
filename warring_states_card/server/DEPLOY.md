# Railway 部署配置
# 1. 创建 Railway 项目
railway init

# 2. 添加 PostgreSQL 数据库
railway add postgresql

# 3. 添加 Redis
railway add redis

# 4. 部署
railway up

# 5. 获取数据库连接字符串
railway variables

# 6. 环境变量配置（可选）
railway variables set JWT_SECRET "your-secret-key"
railway variables set NODE_ENV "production"

# 7. 初始化数据库表结构
railway run npx prisma db push

# 8. 查看日志
railway logs

# 获取公网地址
railway domain