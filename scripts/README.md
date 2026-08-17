# 发布验证流程（根治线上线下不一致）

本项目反复出现「本地代码与线上/容器不一致」问题，根源是部署后没有自动校验产物一致性。
本目录脚本通过**指纹比对**在每次发布时强制校验，不一致即失败/告警。

> 注：项目使用 git-lfs（67 个文件），`.git/hooks/` 已被 lfs 占用。
> 为避免破坏 lfs 的 pre-push/post-commit 钩子，**本流程采用独立命令而非 git hook**。

## 核心脚本

| 脚本 | 作用 |
|------|------|
| `fingerprint.sh` | 从 `main.dart.js` 抽取关键特征指纹（home.download / __adOpenSmartLink / adsterra-banner-slot / /privacy / hero_char） |
| `verify_deploy.sh` | 轮询线上 `DEPLOY_URL` 直到指纹与本地 build 一致（等 Railway 部署完成） |
| `verify_local.sh` | 校验本地 docker 容器 `zg_web` 与本地 build 一致（含 nginx /privacy 路由、privacy.html、首页） |

## 用法

### 1. 本地开发流程（每次改代码后）

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=http://localhost:3000 \
  --dart-define=API_HOST=localhost

rm -rf build/web/dl
docker cp build/web/. zg_web:/usr/share/nginx/html/
docker exec zg_web sh -c 'rm -rf /usr/share/nginx/html/dl'
docker cp nginx.conf zg_web:/etc/nginx/conf.d/default.conf
docker exec zg_web sh -c 'envsubst "\$PORT" < /etc/nginx/conf.d/default.conf > /tmp/d && mv /tmp/d /etc/nginx/conf.d/default.conf'
docker exec zg_web nginx -s reload

sh scripts/verify_local.sh          # 校验本地一致性
```

### 2. 发布到线上（push 触发 Railway）

```bash
git push origin main
# 等待 push 完成（Railway 开始构建）
sh scripts/verify_deploy.sh          # 自动轮询线上，直到与本地 build 一致
```

`verify_deploy.sh` 会输出 `✓✓ 线上已与本地构建完全一致`，否则告警/超时退出非 0。

## 环境变量

| 变量 | 默认 | 说明 |
|------|------|------|
| `DEPLOY_URL` | `https://wscard.games` | 线上站点根 |
| `MAX_WAIT_SEC` | `300` | 等待部署最大秒数 |
| `POLL_INTERVAL` | `15` | 轮询间隔秒数 |
| `LOCAL_BUILD` | `build/web/main.dart.js` | 本地构建产物路径 |

## 常见问题

- **verify_deploy 提示不一致/超时**：Railway 构建失败、部署未触发、或 Dockerfile 与本地 Flutter 版本不同（指纹可能因编译差异不同 → 属正常，此时比对的是「是否随源码更新」）。
- **浏览器仍显示旧版（home.legal / 跳广告）**：这是浏览器 service worker 缓存，脚本无法覆盖。需 `F12 → Application → Storage → Clear site data` 或开无痕窗口。
