import { nitroApp } from 'nitropack';
import { initDatabase, closeConnections } from './utils/database';
import { setupWebSocket } from './routes/_ws';

// 初始化
async function start() {
  try {
    // 初始化数据库和Redis
    await initDatabase();
    
    // 启动HTTP服务器
    const server = nitroApp.listen(3000, () => {
      console.log('Server running on http://localhost:3000');
    });
    
    // 设置WebSocket
    setupWebSocket(server);
    
    console.log('WebSocket server initialized');
    
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// 优雅关闭
process.on('SIGINT', async () => {
  console.log('Shutting down...');
  await closeConnections();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('Shutting down...');
  await closeConnections();
  process.exit(0);
});

start();