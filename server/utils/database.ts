import { PrismaClient } from '@prisma/client';
import jwt from 'jsonwebtoken';
import { verifyAppleReceipt, IAP_GEM_MAP } from './apple_iap.ts';
import { randomBytes, scryptSync, timingSafeEqual } from 'node:crypto';

// 环境变量
const DATABASE_URL = process.env.DATABASE_URL || 'postgresql://postgres:***@localhost:5432/warring_states';
const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';
const JWT_SECRET = process.env.JWT_SECRET || 'warring-states-secret-key-change-in-production';
const ELO_K_FACTOR = 32;

// ── 运营配置（环境变量可覆盖）───────────────────────────────────────────────
const NEW_USER_BONUS_DIAMONDS = Number(process.env.NEW_USER_BONUS_DIAMONDS || 100);
// 新用户活动结束时间（ISO）。缺省 = 服务启动 +30 天（"持续一个月"）。
const NEW_USER_BONUS_UNTIL = process.env.NEW_USER_BONUS_UNTIL
  ? new Date(process.env.NEW_USER_BONUS_UNTIL).getTime()
  : (Date.now() + 30 * 86400_000);
const REFERRAL_BONUS_DIAMONDS = Number(process.env.REFERRAL_BONUS_DIAMONDS || 50);
const CHECKIN_GOLD = Number(process.env.CHECKIN_GOLD || 500);
const CHECKIN_BONUS_GOLD = Number(process.env.CHECKIN_BONUS_GOLD || 2000);
const CHECKIN_BONUS_STREAK = Number(process.env.CHECKIN_BONUS_STREAK || 8);
const CHECKIN_TZ_OFFSET_H = Number(process.env.CHECKIN_TZ_OFFSET_HOURS || 8);

// Prisma 连接池配置
export const prisma = new PrismaClient({
  datasources: {
    db: { url: DATABASE_URL },
  },
  log: process.env.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
});

/** 启动时幂等建表（PlayerSave），避免依赖外部 migration */
export async function ensurePlayerSaveTable() {
  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS "player_saves" (
      "player_id" TEXT NOT NULL,
      "data" JSONB NOT NULL,
      "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT "player_saves_pkey" PRIMARY KEY ("player_id")
    );
  `).catch(() => {});
}
ensurePlayerSaveTable();

/** 启动时幂等建表（SupportTicket），避免依赖外部 migration */
export async function ensureSupportTicketTable() {
  await prisma.$executeRawUnsafe(`
    CREATE TABLE IF NOT EXISTS "support_tickets" (
      "id" TEXT NOT NULL,
      "player_id" TEXT NOT NULL,
      "category" TEXT NOT NULL DEFAULT 'other',
      "message" TEXT NOT NULL,
      "contact" TEXT,
      "platform" TEXT,
      "data" JSONB NOT NULL,
      "status" TEXT NOT NULL DEFAULT 'open',
      "closed_at" TIMESTAMP(3),
      "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT "support_tickets_pkey" PRIMARY KEY ("id")
    );
  `).catch(() => {});
  await prisma.$executeRawUnsafe(`
    CREATE INDEX IF NOT EXISTS "support_tickets_status_created_at_idx"
    ON "support_tickets" ("status", "created_at");
  `).catch(() => {});
}
ensureSupportTicketTable();

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
      redisClient = { get: async () => null, set: async () => null, del: async () => {} };
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

export async function register(email: string, password: string, name: string, referrerId?: string) {
  const existing = await prisma.player.findUnique({ where: { email } });
  if (existing) return { error: '邮箱已注册' };
  const guestToken = crypto.randomUUID();
  const passwordHash = hashPassword(password);
  // 邀请人必须是注册用户（有邮箱）且不能是自己
  let referrer = null;
  if (referrerId) {
    referrer = await prisma.player.findUnique({ where: { id: referrerId } });
    if (referrer && !referrer.email) referrer = null; // 必须注册用户
  }
  const player = await prisma.player.create({
    data: {
      guestToken, email, passwordHash,
      name: name || email.split('@')[0],
      referrerId: referrer?.id ?? null,
    },
  });
  await prisma.collection.create({ data: { playerId: player.id, cards: [] } });
  // 新用户活动期间赠送钻石（失败不阻止注册）
  if (Date.now() < NEW_USER_BONUS_UNTIL) {
    await addGems(player.id, NEW_USER_BONUS_DIAMONDS, '新用户注册奖励').catch(() => {});
  }
  // 邀请奖励：邀请人与被邀请的新用户各得钻石（与公告"各得50钻石"一致）
  if (referrer) {
    await addGems(referrer.id, REFERRAL_BONUS_DIAMONDS, `邀请新用户奖励`).catch(() => {});
    await addGems(player.id, REFERRAL_BONUS_DIAMONDS, '受邀注册奖励').catch(() => {});
  }
  // 重新读取最新余额（含赠钻）
  const updated = await prisma.player.findUnique({ where: { id: player.id } });
  const token = createToken({ playerId: player.id, guestToken });
  return {
    token,
    player: {
      id: player.id, name: player.name, rank: player.rank, email: player.email,
      gems: updated?.gems ?? 0, gold: updated?.gold ?? 100,
    },
  };
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
      data: { playerId: odID, type: txType, currency, amount, balanceAfter: newBalance, detail, externalId, platform: 'web' },
    }),
  ]);
}

/** Xsolla webhook 专用：加钻 + 幂等检查 */
export async function addGemsFromXsolla(odID: string, amount: number, externalId: string) {
  try {
    // Redis 锁防 webhook 并发重试双发；余额乐观锁兜底
    const redis = await getRedisClient();
    let lockOk: any = null;
    try {
      lockOk = await redis.set(`xsolla:${externalId}`, '1', { NX: true, EX: 300 });
    } catch {}
    if (lockOk !== null && !lockOk) {
      await new Promise((r) => setTimeout(r, 500));
      const existing = await prisma.transaction.findFirst({ where: { externalId } });
      if (existing) return { success: true, alreadyProcessed: true };
      return { error: 'Xsolla order processing in progress' };
    }
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
        data: { playerId: odID, type: 'earn_gems', currency: 'gem', amount, balanceAfter: newBalance, detail: 'Xsolla购买', externalId, platform: 'xsolla' },
      }),
    ]);
    return { success: true, gems: newBalance };
  } catch (e: any) {
    return { error: e.message || 'add gems from xsolla failed' };
  }
}

/** Apple IAP 专用：服务端验证 receipt + 幂等发放钻石 */
export async function verifyIAPReceipt(odID: string, receipt: string, productId: string, transactionId?: string) {
  try {
    const info = await verifyAppleReceipt(receipt, productId);
    if ('error' in info) return { error: info.error };

    // 校验 productId 与 receipt 一致
    if (info.productId !== productId) return { error: 'Product mismatch' };
    const amount = IAP_GEM_MAP[productId];
    if (!amount) return { error: 'Invalid product' };

    // 幂等：同一笔交易不重复发放（Redis 锁防并发双发；余额乐观锁兜底）
    const txId = transactionId || info.transactionId;
    const redis = await getRedisClient();
    let lockOk: any = null;
    try {
      lockOk = await redis.set(`iap:${txId}`, '1', { NX: true, EX: 120 });
    } catch {}
    if (lockOk !== null && !lockOk) {
      await new Promise((r) => setTimeout(r, 800));
      const existing = await prisma.transaction.findFirst({ where: { externalId: txId } });
      if (existing) return { success: true, alreadyProcessed: true, gems: existing.balanceAfter, gained: existing.amount };
      return { error: 'IAP verification in progress' };
    }
    const existing = await prisma.transaction.findFirst({ where: { externalId: txId } });
    if (existing) return { success: true, alreadyProcessed: true, gems: existing.balanceAfter, gained: existing.amount };

    const player = await prisma.player.findUnique({ where: { id: odID } });
    if (!player) return { error: 'player not found' };
    const newBalance = player.gems + amount;
    await prisma.$transaction([
      prisma.player.update({
        where: { id: odID, balanceVersion: player.balanceVersion },
        data: { gems: newBalance, balanceVersion: { increment: 1 } },
      }),
      prisma.transaction.create({
        data: { playerId: odID, type: 'earn_gems', currency: 'gem', amount, balanceAfter: newBalance, detail: 'Apple IAP', externalId: txId, platform: 'ios' },
      }),
    ]);
    return { success: true, gems: newBalance, gained: amount };
  } catch (e: any) {
    return { error: e.message || 'verify iap failed' };
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
        data: { playerId: odID, type: 'earn_gems', currency: 'gem', amount, balanceAfter: newBalance, detail: detail || '购买钻石', externalId: receiptId, platform: receiptId ? 'ios' : 'other' },
      }),
    ]);
    return { success: true, gems: newBalance, balanceVersion: player.balanceVersion + 1 };
  } catch (e: any) {
    return { error: e.message || 'add gems failed' };
  }
}

/** 钻石→金币兑换（单事务：扣钻石+发金币+双流水），并发冲突时返回 error 由客户端重试 */
export async function exchangeCurrency(odID: string, gemsCost: number, goldReward: number) {
  try {
    const player = await prisma.player.findUnique({ where: { id: odID } });
    if (!player) return { error: 'player not found' };
    const cost = Math.max(0, Math.floor(Number(gemsCost) || 0));
    const reward = Math.max(0, Math.floor(Number(goldReward) || 0));
    if (player.gems < cost) return { error: 'insufficient gems', gems: player.gems };
    if (reward <= 0 || cost <= 0) return { error: 'invalid amount' };
    const newGems = player.gems - cost;
    const newGold = player.gold + reward;
    await prisma.$transaction([
      prisma.player.update({
        where: { id: odID, balanceVersion: player.balanceVersion },
        data: { gems: newGems, gold: newGold, balanceVersion: { increment: 1 } },
      }),
      prisma.transaction.create({
        data: { playerId: odID, type: 'spend_gems', currency: 'gem', amount: -cost, balanceAfter: newGems, detail: `兑换${reward}金币`, platform: 'web' },
      }),
      prisma.transaction.create({
        data: { playerId: odID, type: 'earn_gold', currency: 'gold', amount: reward, balanceAfter: newGold, detail: '钻石兑换', platform: 'web' },
      }),
    ]);
    return { success: true, gems: newGems, gold: newGold, balanceVersion: player.balanceVersion + 1 };
  } catch (e: any) {
    return { error: e.message || 'exchange failed' };
  }
}

/** 客户端余额对账：本地多于服务端的部分入账（正差），负差忽略；增量更新，不覆盖 */
export async function syncBalance(odID: string, gems: number, gold: number) {
  try {
    const player = await prisma.player.findUnique({ where: { id: odID } });
    if (!player) return { error: 'player not found' };
    const ops: any[] = [];
    const suffix = `${Date.now()}:${Math.random().toString(36).slice(2, 8)}`;
    const gemDelta = gems - player.gems;
    if (gemDelta > 0) {
      ops.push(
        prisma.player.update({ where: { id: odID }, data: { gems: { increment: gemDelta } } }),
        prisma.transaction.create({
          data: { playerId: odID, type: 'earn_gems', currency: 'gem', amount: gemDelta, balanceAfter: player.gems + gemDelta, detail: '客户端同步', externalId: `sync:${odID}:gem:${suffix}`, platform: 'web' },
        }),
      );
    }
    const goldDelta = gold - player.gold;
    if (goldDelta > 0) {
      ops.push(
        prisma.player.update({ where: { id: odID }, data: { gold: { increment: goldDelta } } }),
        prisma.transaction.create({
          data: { playerId: odID, type: 'earn_gold', currency: 'gold', amount: goldDelta, balanceAfter: player.gold + goldDelta, detail: '客户端同步', externalId: `sync:${odID}:gold:${suffix}`, platform: 'web' },
        }),
      );
    }
    if (ops.length) await prisma.$transaction(ops);
    return { success: true, gems: player.gems + gemDelta, gold: player.gold + goldDelta };
  } catch (e: any) {
    return { error: e.message || 'sync balance failed' };
  }
}

/** 购买卡牌/英雄：服务端事务处理（扣款+入档），返回权威状态供客户端落存
 * currency: 'gold' 扣金币；'gem' 扣钻石 */
export async function purchasePlayerAsset(
  odID: string,
  kind: 'card' | 'hero',
  assetId: string,
  cost: number,
  currency: 'gold' | 'gem' = 'gold',
) {
  try {
    const player = await prisma.player.findUnique({ where: { id: odID } });
    if (!player) return { error: 'player not found' };
    const price = Math.max(0, Math.floor(Number(cost) || 0));
    const isGem = currency === 'gem';
    if (isGem ? player.gems < price : player.gold < price) {
      return { error: isGem ? 'insufficient gems' : 'insufficient gold', gold: player.gold, gems: player.gems };
    }

    const save = await prisma.playerSave.findUnique({ where: { playerId: odID } });
    const data = (save?.data as any) || {};
    const pd = data.playerData && typeof data.playerData === 'object' ? { ...data.playerData } : {};
    const key = kind === 'card' ? 'unlockedCards' : 'unlockedHeroes';
    const list: string[] = Array.isArray(pd[key]) ? [...(pd[key] as string[])] : [];
    if (list.includes(assetId)) return { error: 'already owned', gold: player.gold, gems: player.gems };
    list.push(assetId);
    pd[key] = list;
    const newSave = { ...data, playerData: pd };

    const newGold = isGem ? player.gold : player.gold - price;
    const newGems = isGem ? player.gems - price : player.gems;
    await prisma.$transaction([
      prisma.player.update({
        where: { id: odID, balanceVersion: player.balanceVersion },
        data: { gold: newGold, gems: newGems, balanceVersion: { increment: 1 } },
      }),
      prisma.transaction.create({
        data: {
          playerId: odID,
          type: isGem ? 'spend_gems' : 'spend_gold',
          currency: isGem ? 'gem' : 'gold',
          amount: -price,
          balanceAfter: isGem ? newGems : newGold,
          detail: `${kind === 'card' ? '购买卡牌' : '购买英雄'} ${assetId}${isGem ? '（钻石）' : ''}`,
          platform: 'web',
        },
      }),
      prisma.playerSave.upsert({
        where: { playerId: odID },
        update: { data: newSave },
        create: { playerId: odID, data: newSave },
      }),
    ]);
    return {
      success: true,
      gold: newGold,
      gems: newGems,
      balanceVersion: player.balanceVersion + 1,
      unlockedCards: (pd.unlockedCards as string[]) ?? [],
      unlockedHeroes: (pd.unlockedHeroes as string[]) ?? [],
    };
  } catch (e: any) {
    return { error: e.message || 'purchase asset failed' };
  }
}

/** 保存玩家存档（PlayerData + Collection + 战斗历史） */
export async function savePlayerArchive(odID: string, data: any) {
  try {
    if (!data || typeof data !== 'object') return { error: 'Invalid save data' };
    // 空档（新设备默认档）视为无存档：删除云端记录，防止覆盖真实存档
    const pd = data?.playerData;
    const isEmpty =
      pd &&
      pd.gems === 0 &&
      (pd.gold ?? 100) <= 100 &&
      (!Array.isArray(pd.unlockedCards) || pd.unlockedCards.length === 0) &&
      (!Array.isArray(pd.unlockedHeroes) || pd.unlockedHeroes.length <= 1);
    if (isEmpty) {
      await prisma.playerSave.deleteMany({ where: { playerId: odID } });
      return { success: true, cleared: true };
    }
    const saved = await prisma.playerSave.upsert({
      where: { playerId: odID },
      update: { data },
      create: { playerId: odID, data },
    });
    return { success: true, updatedAt: saved.updatedAt.toISOString() };
  } catch (e: any) {
    return { error: e.message || 'save archive failed' };
  }
}

/** 读取玩家完整存档版本（轻量轮询用，只查 updatedAt） */
export async function getPlayerSaveVersion(odID: string) {
  try {
    const row = await prisma.playerSave.findUnique({
      where: { playerId: odID },
      select: { updatedAt: true },
    });
    return { success: true, updatedAt: row ? row.updatedAt.toISOString() : null };
  } catch (e: any) {
    return { error: e.message || 'load save version failed' };
  }
}

/** 读取玩家完整存档 */
export async function getPlayerArchive(odID: string) {
  try {
    const row = await prisma.playerSave.findUnique({ where: { playerId: odID } });
    if (!row) return { success: true, save: null };
    return { success: true, save: row.data, updatedAt: row.updatedAt.toISOString() };
  } catch (e: any) {
    return { error: e.message || 'load archive failed' };
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
        data: { playerId: odID, type: 'spend_gems', currency: 'gem', amount: -amount, balanceAfter: newBalance, detail, platform: 'web' },
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
        data: { playerId: odID, type: 'earn_gold', currency: 'gold', amount, balanceAfter: newBalance, detail, platform: 'web' },
      }),
    ]);
    return { success: true, gold: newBalance, balanceVersion: player.balanceVersion + 1 };
  } catch (e: any) {
    return { error: e.message || 'add gold failed' };
  }
}

// ── 每日打卡 ────────────────────────────────────────────────────────────────
function serDay(d: Date): string {
  const off = CHECKIN_TZ_OFFSET_H * 3600_000;
  return new Date(d.getTime() + off).toISOString().slice(0, 10);
}

export async function checkin(odID: string) {
  try {
    const player = await prisma.player.findUnique({ where: { id: odID } });
    if (!player) return { error: 'player not found' };
    const now = new Date();
    const today = serDay(now);
    const existing = await prisma.checkin.findUnique({
      where: { playerId_date: { playerId: odID, date: today } },
    });
    if (existing) {
      return { success: true, already: true, date: today, streak: existing.streak, gold: 0, bonus: 0 };
    }
    const yesterday = serDay(new Date(now.getTime() - 86400_000));
    const last = await prisma.checkin.findFirst({ where: { playerId: odID }, orderBy: { date: 'desc' } });
    const streak = (last && last.date === yesterday) ? last.streak + 1 : 1;
    const gold = CHECKIN_GOLD;
    const bonus = streak >= CHECKIN_BONUS_STREAK ? CHECKIN_BONUS_GOLD : 0;
    const newGold = player.gold + gold + bonus;
    await prisma.$transaction([
      prisma.checkin.create({ data: { playerId: odID, date: today, streak, bonus } }),
      prisma.player.update({
        where: { id: odID, balanceVersion: player.balanceVersion },
        data: { gold: newGold, balanceVersion: { increment: 1 } },
      }),
      prisma.transaction.create({
        data: {
          playerId: odID, type: 'earn_gold', currency: 'gold',
          amount: gold + bonus, balanceAfter: newGold,
          detail: bonus ? `每日打卡+连续${streak}天额外奖励` : '每日打卡',
          platform: 'web',
        },
      }),
    ]);
    return { success: true, already: false, date: today, streak, gold, bonus, goldTotal: newGold };
  } catch (e: any) {
    return { error: e.message || 'checkin failed' };
  }
}

// ── 系统公告 ────────────────────────────────────────────────────────────────
// 生效周期：startsAt(null=立刻) / endsAt(null=长期)，当前时间落在 [startsAt, endsAt) 才返回
export async function listAnnouncements(locale: string = 'zh') {
  const now = new Date();
  return await prisma.announcement.findMany({
    where: {
      locale,
      AND: [
        { OR: [{ startsAt: null }, { startsAt: { lte: now } }] },
        { OR: [{ endsAt: null }, { endsAt: { gt: now } }] },
      ],
    },
    orderBy: { sort: 'asc' },
    select: { id: true, title: true, content: true },
  });
}

// 后台管理：新增公告（生效周期用 startsAt/endsAt 指定，null 表示不限制）
export async function createAnnouncement(input: {
  locale?: string;
  title: string;
  content: string;
  startsAt?: Date | null;
  endsAt?: Date | null;
  sort?: number;
}) {
  return await prisma.announcement.create({
    data: {
      locale: input.locale || 'zh',
      title: input.title,
      content: input.content,
      startsAt: input.startsAt ?? null,
      endsAt: input.endsAt ?? null,
      sort: input.sort ?? 0,
    },
  });
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
        data: { playerId: odID, type: 'spend_gold', currency: 'gold', amount: -amount, balanceAfter: newBalance, detail, platform: 'web' },
      }),
    ]);
    return { success: true, gold: newBalance, balanceVersion: player.balanceVersion + 1 };
  } catch (e: any) {
    return { error: e.message || 'spend gold failed' };
  }
}

export async function getTransactions(odID: string, days: number = 3) {
  // days<=0 表示查询全部历史
  const since = days > 0 ? new Date(Date.now() - days * 86400000) : undefined;
  const txns = await prisma.transaction.findMany({
    where: { playerId: odID, ...(since ? { createdAt: { gte: since } } : {}) },
    orderBy: { createdAt: 'desc' },
    take: 2000,
  });
  return txns;
}

// ─── 客服工单 ───
/** 创建工单：自动附带玩家信息 + 近30天订单流水快照 */
export async function createSupportTicket(
  playerId: string,
  input: { category?: string; message: string; contact?: string; platform?: string },
) {
  const player = await prisma.player.findUnique({
    where: { id: playerId },
    select: { id: true, name: true, email: true },
  });
  const transactions = await getTransactions(playerId, 30);
  const ticket = await prisma.supportTicket.create({
    data: {
      playerId,
      category: input.category || 'other',
      message: input.message,
      contact: input.contact?.trim() || null,
      platform: input.platform?.trim() || null,
      data: { player, transactions },
    },
  });
  return { id: ticket.id, createdAt: ticket.createdAt };
}

/** 客服后台：拉取工单列表（open / closed / 全部） */
export async function listSupportTickets(status?: string, limit: number = 50) {
  return prisma.supportTicket.findMany({
    where: status === 'open' || status === 'closed' ? { status } : undefined,
    orderBy: { createdAt: 'desc' },
    take: Math.min(Math.max(limit, 1), 200),
  });
}

/** 客服后台：关闭工单 */
export async function closeSupportTicket(id: string) {
  const ticket = await prisma.supportTicket.update({
    where: { id },
    data: { status: 'closed', closedAt: new Date() },
  });
  return { id: ticket.id, status: ticket.status };
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
