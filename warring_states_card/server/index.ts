import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function start() {
  try {
    console.log('Connecting to database...');
    await prisma.$connect();
    console.log('Database connected');
    
    console.log('Server ready on port 3000');
  } catch (error) {
    console.error('Failed to start:', error);
    process.exit(1);
  }
}

process.on('SIGINT', async () => {
  console.log('Shutting down...');
  await prisma.$disconnect();
  process.exit(0);
});

start();
