import { PrismaClient } from '@prisma/client';
import { createClient, RedisClientType } from 'redis';
import jwt from 'jsonwebtoken';

// 环境变量
const DATABASE_URL = process.env.DATABASE_URL || 'postgresql://postgres:password@localhost:5432/warring_states';
const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';
const JWT_SECRET = process.env.JWT_SECRET || 'warring-states-secret-key-change-in-production';
const ELO_K_FACTOR = 32; // ELO K因子

// 数据库连接
export const prisma = new PrismaClient({
  datasources: {
    db: {
      url: DATABASE_URL,
    },
  },
});

// Redis连接
let redis: RedisClientType | null = null;

export async function getRedis(): Promise<RedisClientType> {
  if (!redis) {
    redis = createClient({ url: REDIS_URL });
    await redis.connect();
  }
  return redis;
}

// JWT验证
export interface TokenPayload {
  playerId: string;
  guestToken: string;
}

export function verifyToken(token: string): TokenPayload | null {
  try {
    return jwt.verify(token, JWT_SECRET) as TokenPayload;
  } catch {
    return null;
  }
}

export function createToken(payload: TokenPayload): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '30d' });
}

// ELO积分计算
export function calculateElo(
  winnerElo: number,
  loserElo: number,
): { winnerNew: number; loserNew: number } {
  const expectedWinner = 1 / (1 + Math.pow(10, (loserElo - winnerElo) / 400));
  const expectedLoser = 1 / (1 + Math.pow(10, (winnerElo - loserElo) / 400));
  
  const winnerNew = Math.round(winnerElo + ELO_K_FACTOR * (1 - expectedWinner));
  const loserNew = Math.round(loserElo + ELO_K_FACTOR * (0 - expectedLoser));
  
  return { winnerNew, loserNew };
}

// 排行榜更新
export async function updateLeaderboard(
  season: string,
  playerId: string,
  playerName: string,
  elo: number,
  wins: number,
): Promise<void> {
  const redis = await getRedis();
  
  // 获取当前排名
  const rank = await redis.zrevrank(`leaderboard:${season}`, playerId);
  const newRank = rank ?? 0;
  
  await prisma.leaderboard.upsert({
    where: {
      season_rank: { season, rank: newRank },
    },
    update: { elo, wins, playerName, updatedAt: new Date() },
    create: { season, rank: newRank, playerId, playerName, elo, wins },
  });
}

// 玩家等级计算
export function calculateRank(elo: number): number {
  if (elo < 1000) return 1;
  if (elo < 1100) return 2;
  if (elo < 1200) return 3;
  if (elo < 1300) return 4;
  if (elo < 1400) return 5;
  if (elo < 1500) return 6;
  if (elo < 1600) return 7;
  if (elo < 1700) return 8;
  if (elo < 1800) return 9;
  if (elo < 1900) return 10;
  if (elo < 2000) return 11;
  if (elo < 2100) return 12;
  if (elo < 2200) return 13;
  if (elo < 2300) return 14;
  if (elo < 2400) return 15;
  if (elo < 2500) return 16;
  if (elo < 2600) return 17;
  if (elo < 2700) return 18;
  if (elo < 2800) return 19;
  return 20; // 大师
}

// 段位名称
export function getRankName(rank: number): string {
  const names = [
    '', '青铜一', '青铜二', '青铜三', '白银一', '白银二', '白银三', '黄金一', '黄金二', '黄金三',
    '钻石一', '钻石二', '钻石三', '大师一', '大师二', '大师三', '宗师一', '宗师二', '宗师三', '王者',
  ];
  return names[rank] || '青铜一';
}

// 初始化数据库
export async function initDatabase(): Promise<void> {
  try {
    await prisma.$connect();
    console.log('✓ Database connected');
    
    // 初始化Redis
    await getRedis();
    console.log('✓ Redis connected');
    
    // 初始化每日任务模板
    await initDailyQuests();
    console.log('✓ Daily quests initialized');
  } catch (error) {
    console.error('Database initialization failed:', error);
    throw error;
  }
}

// 初始化每日任务
async function initDailyQuests(): Promise<void> {
  const questTemplates = [
    { type: 'daily', questType: 'win', target: 3, reward: 100, name: '每日胜利' },
    { type: 'daily', questType: 'play', target: 5, reward: 50, name: '每日对局' },
    { type: 'weekly', questType: 'win', target: 15, reward: 500, name: '每周胜利' },
  ];
  
  // 任务模板预存，实际生成在玩家登录时
  console.log('Quest templates:', questTemplates);
}

// 清理过期数据
export async function cleanupExpiredData(): Promise<void> {
  const now = new Date();
  
  // 删除过期的每日任务
  await prisma.quest.deleteMany({
    where: {
      expiresAt: { lt: now },
      claimed: true,
    },
  });
  
  console.log('Cleanup completed');
}

// 关闭连接
export async function closeConnections(): Promise<void> {
  await prisma.$disconnect();
  if (redis) {
    await redis.quit();
  }
}