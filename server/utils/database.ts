import { PrismaClient } from '@prisma/client';
import jwt from 'jsonwebtoken';
import { randomBytes, scryptSync, timingSafeEqual } from 'node:crypto';

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
  const names = ['', '青铜一', '青铜二', '青铜三', '白银一', '白银二', '白银三', '黄金一', '黄金二', '黄金三', '钻石一', '钻石二', '钻石三', '大师一', '大师二', '大师三', '宗师一', '宗师二', '宗师三', '传奇', '王者'];
  return names[rank] || '青铜一';
}

// 匹配队列 (Redis)
async function getMatchQueueRedis() {
  const redis = await getRedisClient();
  return redis;
}

// 内存匹配队列 (备用)
const matchQueue: Array<{ odID: string; odName: string; odHeroId: string; rating: number }> = [];

// 待通知的匹配结果（双方轮询时都能拿到）
const pendingMatches = new Map<string, { opponent: any; roomId: string }>();

// ─── 密码工具 ───
function hashPassword(password: string): string {
  const salt = randomBytes(16).toString('hex');
  const derivedKey = scryptSync(password, salt, 64).toString('hex');
  return `${salt}:${derivedKey}`;
}

function verifyPassword(password: string, hash: string): boolean {
  const [salt, key] = hash.split(':');
  const derivedKey = scryptSync(password, salt, 64).toString('hex');
  return key.length === derivedKey.length && timingSafeEqual(Buffer.from(key), Buffer.from(derivedKey));
}

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

export async function register(email: string, password: string, name: string) {
  const existing = await prisma.player.findUnique({ where: { email } });
  if (existing) return { error: '邮箱已注册' };
  const guestToken = crypto.randomUUID();
  const passwordHash = hashPassword(password);
  const player = await prisma.player.create({
    data: { guestToken, email, passwordHash, name: name || email.split('@')[0] },
  });
  await prisma.collection.create({ data: { playerId: player.id, cards: [] } });
  const token = createToken({ playerId: player.id, guestToken });
  return { token, player: { id: player.id, name: player.name, rank: player.rank, email: player.email } };
}

export async function login(email: string, password: string) {
  const player = await prisma.player.findUnique({ where: { email } });
  if (!player || !player.passwordHash) return { error: '邮箱或密码错误' };
  if (!verifyPassword(password, player.passwordHash)) return { error: '邮箱或密码错误' };
  const token = createToken({ playerId: player.id, guestToken: player.guestToken });
  return { token, player: { id: player.id, name: player.name, rank: player.rank, email: player.email } };
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
  // 1. 先查是否有待通知的匹配结果（别人匹配到的对手）
  const pending = pendingMatches.get(odID);
  if (pending) {
    pendingMatches.delete(odID);
    return { matched: true, opponent: pending.opponent, roomId: pending.roomId };
  }

  // 2. 移除自己的旧队列条目
  const selfIdx = matchQueue.findIndex(e => e.odID === odID);
  if (selfIdx >= 0) matchQueue.splice(selfIdx, 1);

  // 3. 尝试匹配其他排队玩家
  for (let i = 0; i < matchQueue.length; i++) {
    const entry = matchQueue[i];
    if (entry.odID !== odID && Math.abs(entry.rating - rating) < 200) {
      matchQueue.splice(i, 1);
      const matchId = crypto.randomUUID();
      createRoom(matchId, { odID, odHeroId }, { odID: entry.odID, odHeroId: entry.odHeroId });

      // 给对手存一份待通知结果
      pendingMatches.set(entry.odID, {
        opponent: { odID, odHeroId, odName: '对手' },
        roomId: matchId,
      });

      return { matched: true, opponent: entry, roomId: matchId };
    }
  }
  return { matched: false };
}

// ─── 游戏房间 + 动作中继 ───
interface GameRoom {
  matchId: string;
  players: string[];     // [odID, odID]
  heroIds: string[];     // [heroId, heroId]
  created: number;
  lastAction: number;
}

interface StoredAction {
  seq: number;
  odID: string;
  action: any;
  ts: number;
}

const rooms = new Map<string, GameRoom>();
const roomActions = new Map<string, StoredAction[]>();

export function createRoom(matchId: string, p1: { odID: string; odHeroId: string }, p2: { odID: string; odHeroId: string }): GameRoom {
  const room: GameRoom = {
    matchId,
    players: [p1.odID, p2.odID],
    heroIds: [p1.odHeroId, p2.odHeroId],
    created: Date.now(),
    lastAction: Date.now(),
  };
  rooms.set(matchId, room);
  roomActions.set(matchId, []);
  return room;
}

export async function submitGameAction(matchId: string, odID: string, seq: number, action: any) {
  const room = rooms.get(matchId);
  if (!room) return { error: 'room not found' };
  if (!room.players.includes(odID)) return { error: 'not in room' };

  const actions = roomActions.get(matchId) || [];
  const stored: StoredAction = { seq, odID, action, ts: Date.now() };
  actions.push(stored);
  room.lastAction = Date.now();

  // 只保留最近 200 个动作
  while (actions.length > 200) actions.shift();

  return { success: true, seq };
}

export async function pollGameActions(matchId: string, afterSeq: number) {
  const room = rooms.get(matchId);
  if (!room) return { actions: [], room: null };

  const actions = roomActions.get(matchId) || [];
  const newActions = actions.filter(a => a.seq > afterSeq);

  return {
    actions: newActions,
    room: {
      matchId: room.matchId,
      players: room.players,
      heroIds: room.heroIds,
      created: room.created,
    },
  };
}

// ─── 资产（钻石/金币）包含乐观锁版本号 ───

export async function getBalance(odID: string) {
  const player = await prisma.player.findUnique({ where: { id: odID } });
  if (!player) return { error: 'player not found' };
  return {
    gems: player.gems,
    gold: player.gold,
    balanceVersion: player.balanceVersion,
  };
}

async function _addBalance(odID: string, currency: string, amount: number, detail: string, externalId?: string) {
  const player = await prisma.player.findUnique({ where: { id: odID } });
  if (!player) throw new Error('player not found');
  const field = currency === 'gem' ? 'gems' : 'gold';
  const current = player[field] as number;
  const newBalance = current + amount;
  const txType = amount > 0 ? `earn_${currency}s` : `spend_${currency}s`;

  await prisma.$transaction([
    prisma.player.update({
      where: { id: odID, balanceVersion: player.balanceVersion },
      data: { [field]: newBalance, balanceVersion: { increment: 1 } },
    }),
    prisma.transaction.create({
      data: { playerId: odID, type: txType, currency, amount, balanceAfter: newBalance, detail, externalId },
    }),
  ]);
}

/** Xsolla webhook 专用：加钻 + 幂等检查 */
export async function addGemsFromXsolla(odID: string, amount: number, externalId: string) {
  try {
    // 幂等检查：同一笔 transaction 不重复加
    const existing = await prisma.transaction.findFirst({
      where: { externalId },
    });
    if (existing) return { success: true, alreadyProcessed: true };

    const player = await prisma.player.findUnique({ where: { id: odID } });
    if (!player) return { error: 'player not found' };
    const newBalance = player.gems + amount;
    await prisma.$transaction([
      prisma.player.update({
        where: { id: odID, balanceVersion: player.balanceVersion },
        data: { gems: newBalance, balanceVersion: { increment: 1 } },
      }),
      prisma.transaction.create({
        data: { playerId: odID, type: 'earn_gems', currency: 'gem', amount, balanceAfter: newBalance, detail: 'Xsolla购买', externalId },
      }),
    ]);
    return { success: true, gems: newBalance };
  } catch (e: any) {
    return { error: e.message || 'add gems from xsolla failed' };
  }
}

export async function addGems(odID: string, amount: number, detail: string = '', receiptId?: string) {
  try {
    const player = await prisma.player.findUnique({ where: { id: odID } });
    if (!player) return { error: 'player not found' };
    const newBalance = player.gems + amount;
    await prisma.$transaction([
      prisma.player.update({
        where: { id: odID, balanceVersion: player.balanceVersion },
        data: { gems: newBalance, balanceVersion: { increment: 1 } },
      }),
      prisma.transaction.create({
        data: { playerId: odID, type: 'earn_gems', currency: 'gem', amount, balanceAfter: newBalance, detail: detail || '购买钻石', externalId: receiptId },
      }),
    ]);
    return { success: true, gems: newBalance, balanceVersion: player.balanceVersion + 1 };
  } catch (e: any) {
    return { error: e.message || 'add gems failed' };
  }
}

export async function spendGems(odID: string, amount: number, detail: string = '') {
  try {
    const player = await prisma.player.findUnique({ where: { id: odID } });
    if (!player) return { error: 'player not found' };
    if (player.gems < amount) return { error: 'insufficient gems', gems: player.gems };
    const newBalance = player.gems - amount;
    await prisma.$transaction([
      prisma.player.update({
        where: { id: odID, balanceVersion: player.balanceVersion },
        data: { gems: newBalance, balanceVersion: { increment: 1 } },
      }),
      prisma.transaction.create({
        data: { playerId: odID, type: 'spend_gems', currency: 'gem', amount: -amount, balanceAfter: newBalance, detail },
      }),
    ]);
    return { success: true, gems: newBalance, balanceVersion: player.balanceVersion + 1 };
  } catch (e: any) {
    return { error: e.message || 'spend failed' };
  }
}

export async function addGold(odID: string, amount: number, detail: string = '') {
  try {
    const player = await prisma.player.findUnique({ where: { id: odID } });
    if (!player) return { error: 'player not found' };
    const newBalance = player.gold + amount;
    await prisma.$transaction([
      prisma.player.update({
        where: { id: odID, balanceVersion: player.balanceVersion },
        data: { gold: newBalance, balanceVersion: { increment: 1 } },
      }),
      prisma.transaction.create({
        data: { playerId: odID, type: 'earn_gold', currency: 'gold', amount, balanceAfter: newBalance, detail },
      }),
    ]);
    return { success: true, gold: newBalance, balanceVersion: player.balanceVersion + 1 };
  } catch (e: any) {
    return { error: e.message || 'add gold failed' };
  }
}

export async function spendGold(odID: string, amount: number, detail: string = '') {
  try {
    const player = await prisma.player.findUnique({ where: { id: odID } });
    if (!player) return { error: 'player not found' };
    if (player.gold < amount) return { error: 'insufficient gold', gold: player.gold };
    const newBalance = player.gold - amount;
    await prisma.$transaction([
      prisma.player.update({
        where: { id: odID, balanceVersion: player.balanceVersion },
        data: { gold: newBalance, balanceVersion: { increment: 1 } },
      }),
      prisma.transaction.create({
        data: { playerId: odID, type: 'spend_gold', currency: 'gold', amount: -amount, balanceAfter: newBalance, detail },
      }),
    ]);
    return { success: true, gold: newBalance, balanceVersion: player.balanceVersion + 1 };
  } catch (e: any) {
    return { error: e.message || 'spend gold failed' };
  }
}

export async function getTransactions(odID: string, limit: number = 50) {
  const txns = await prisma.transaction.findMany({
    where: { playerId: odID },
    orderBy: { createdAt: 'desc' },
    take: limit,
  });
  return txns;
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
