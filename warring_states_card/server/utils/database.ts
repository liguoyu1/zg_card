import { PrismaClient } from '@prisma/client';
import jwt from 'jsonwebtoken';

// 环境变量
const DATABASE_URL = process.env.DATABASE_URL || 'postgresql://postgres:***@localhost:5432/warring_states';
const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';
const JWT_SECRET = process.env.JWT_SECRET || 'warring-states-secret-key-change-in-production';
const ELO_K_FACTOR = 32;

// Prisma 连接池配置
export const prisma = new PrismaClient({
  datasources: {
    db: { url: DATABASE_URL },
  },
  log: process.env.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
});

// Redis 客户端
let redisClient: any = null;

async function getRedisClient() {
  if (!redisClient) {
    try {
      const { createClient } = await import('redis');
      redisClient = createClient({ url: REDIS_URL });
      await redisClient.connect();
      console.log('[Redis] Connected');
    } catch (e) {
      console.log('[Redis] Not available, using memory cache');
      redisClient = { get: async () => null, set: async () => {}, del: async () => {} };
    }
  }
  return redisClient;
}

// 内存缓存 (备用)
const memoryCache = new Map<string, { data: any; expire: number }>();

async function cacheGet(key: string): Promise<any | null> {
  try {
    const redis = await getRedisClient();
    const data = await redis.get(key);
    if (data) return JSON.parse(data);
  } catch {}
  // 内存缓存
  const mem = memoryCache.get(key);
  if (mem && mem.expire > Date.now()) return mem.data;
  return null;
}

async function cacheSet(key: string, data: any, ttl: number = 60) {
  try {
    const redis = await getRedisClient();
    await redis.set(key, JSON.stringify(data), { EX: ttl });
  } catch {}
  // 内存缓存
  memoryCache.set(key, { data, expire: Date.now() + ttl * 1000 });
}

async function cacheDel(key: string) {
  try {
    const redis = await getRedisClient();
    await redis.del(key);
  } catch {}
  memoryCache.delete(key);
}

// JWT
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

// ELO计算
export function calculateElo(winnerElo: number, loserElo: number) {
  const expectedWinner = 1 / (1 + Math.pow(10, (loserElo - winnerElo) / 400));
  const winnerNew = Math.round(winnerElo + ELO_K_FACTOR * (1 - expectedWinner));
  const loserNew = Math.round(loserElo - (winnerNew - winnerElo));
  return { winnerNew, loserNew };
}

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
  return 20;
}

export function getRankName(rank: number): string {
  const names = ['', '青铜一', '青铜二', '青铜三', '白银一', '白银二', '白银三', '黄金一', '黄金二', '黄金三', '钻石一', '钻石二', '钻石三', '大师一', '大师二', '大师三', '宗师一', '宗师二', '宗师三', '王者'];
  return names[rank] || '青铜一';
}

// 匹配队列 (Redis)
async function getMatchQueueRedis() {
  const redis = await getRedisClient();
  return redis;
}

// 内存匹配队列 (备用)
const matchQueue: Array<{ odID: string; odName: string; odHeroId: string; rating: number }> = [];

export async function guestLogin(name: string) {
  const guestToken = crypto.randomUUID();
  const player = await prisma.player.create({
    data: {
      guestToken,
      name: name || `玩家${Math.floor(Math.random() * 9999)}`,
    },
  });
  await prisma.collection.create({ data: { playerId: player.id, cards: [] } });
  const token = createToken({ playerId: player.id, guestToken });
  return { token, player: { id: player.id, name: player.name, rank: player.rank } };
}

export async function getPlayerProfile(playerId: string) {
  const cacheKey = `player:${playerId}`;
  const cached = await cacheGet(cacheKey);
  if (cached) return cached;
  
  const profile = await prisma.player.findUnique({ 
    where: { id: playerId }, 
    include: { decks: true, quests: true } 
  });
  
  if (profile) await cacheSet(cacheKey, profile, 300);
  return profile;
}

export async function updatePlayerStats(playerId: string, won: boolean, opponentRating?: number) {
  const player = await prisma.player.findUnique({ where: { id: playerId } });
  if (!player) return null;
  
  let newElo = player.elo;
  if (opponentRating) {
    const { winnerNew } = calculateElo(won ? player.elo : opponentRating, won ? opponentRating : player.elo);
    newElo = winnerNew;
  }
  
  const updated = await prisma.player.update({
    where: { id: playerId },
    data: { 
      wins: player.wins + (won ? 1 : 0), 
      losses: player.losses + (won ? 0 : 1), 
      elo: newElo, 
      rank: calculateRank(newElo) 
    },
  });
  
  await cacheDel(`player:${playerId}`);
  await cacheDel('leaderboard:top100');
  return updated;
}

export async function getLeaderboard(limit: number = 100) {
  const cacheKey = `leaderboard:${limit}`;
  const cached = await cacheGet(cacheKey);
  if (cached) return cached;
  
  const leaderboard = await prisma.player.findMany({ 
    orderBy: { elo: 'desc' }, 
    take: limit, 
    select: { id: true, name: true, elo: true, wins: true, rank: true } 
  });
  
  await cacheSet(cacheKey, leaderboard, 60);
  return leaderboard;
}

export async function getPlayerRank(playerId: string) {
  const cacheKey = `rank:${playerId}`;
  const cached = await cacheGet(cacheKey);
  if (cached !== null) return cached;
  
  const player = await prisma.player.findUnique({ where: { id: playerId } });
  if (!player) return null;
  
  const rank = await prisma.player.count({ where: { elo: { gt: player.elo } } }) + 1;
  await cacheSet(cacheKey, rank, 300);
  return rank;
}

export async function joinMatchQueue(entry: { odID: string; odName: string; odHeroId: string; rating: number }) {
  matchQueue.push(entry);
  return { status: 'queued', queueSize: matchQueue.length };
}

export async function leaveMatchQueue(odID: string) {
  const idx = matchQueue.findIndex(e => e.odID === odID);
  if (idx >= 0) matchQueue.splice(idx, 1);
  return { success: true };
}

export async function checkMatchStatus(odID: string, odHeroId: string, rating: number) {
  for (let i = 0; i < matchQueue.length; i++) {
    const entry = matchQueue[i];
    if (entry.odID !== odID && Math.abs(entry.rating - rating) < 200) {
      matchQueue.splice(i, 1);
      return { matched: true, opponent: entry, roomId: crypto.randomUUID() };
    }
  }
  return { matched: false };
}

export async function initDatabase() {
  console.log('[DB] Connecting to:', DATABASE_URL.substring(0, 40) + '...');
  await prisma.$connect();
  console.log('[DB] Connected');
}

export async function closeConnections() {
  await prisma.$disconnect();
  if (redisClient) {
    await redisClient.quit();
  }
}
