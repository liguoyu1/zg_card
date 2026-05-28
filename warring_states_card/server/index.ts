import { initDatabase, closeConnections } from './utils/database';

async function start() {
  try {
    await initDatabase();
    console.log('Database initialized');
    console.log('Server ready on port 3000');
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

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
