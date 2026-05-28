import { PrismaClient } from '@prisma/client';
import * as jwt from 'jsonwebtoken';

// 环境变量
const DATABASE_URL = process.env.DATABASE_URL || 'postgresql://postgres:***@localhost:5432/warring_states';
const JWT_SECRET = process.env.JWT_SECRET || 'warring-states-secret-key-change-in-production';
const ELO_K_FACTOR = 32;

// 数据库连接
export const prisma = new PrismaClient({
  datasources: {
    db: { url: DATABASE_URL },
  },
});

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

// 内存匹配队列
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
  return prisma.player.findUnique({ where: { id: playerId }, include: { decks: true, quests: true } });
}

export async function updatePlayerStats(playerId: string, won: boolean, opponentRating?: number) {
  const player = await prisma.player.findUnique({ where: { id: playerId } });
  if (!player) return null;
  let newElo = player.elo;
  if (opponentRating) {
    const { winnerNew } = calculateElo(won ? player.elo : opponentRating, won ? opponentRating : player.elo);
    newElo = winnerNew;
  }
  return prisma.player.update({
    where: { id: playerId },
    data: { wins: player.wins + (won ? 1 : 0), losses: player.losses + (won ? 0 : 1), elo: newElo, rank: calculateRank(newElo) },
  });
}

export async function getLeaderboard(limit: number = 100) {
  return prisma.player.findMany({ orderBy: { elo: 'desc' }, take: limit, select: { id: true, name: true, elo: true, wins: true, rank: true } });
}

export async function getPlayerRank(playerId: string) {
  const player = await prisma.player.findUnique({ where: { id: playerId } });
  if (!player) return null;
  return await prisma.player.count({ where: { elo: { gt: player.elo } } }) + 1;
}

export async function joinMatchQueue(entry: { odID: string; odName: string; odHeroId: string; rating: number }) {
  matchQueue.push(entry);
  return { status: 'queued' };
}

export async function leaveMatchQueue(odID: string) {
  const idx = matchQueue.findIndex(e => e.odID === odID);
  if (idx >= 0) matchQueue.splice(idx, 1);
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
  console.log('Database URL:', DATABASE_URL.substring(0, 30) + '...');
}

export async function closeConnections() {
  await prisma.$disconnect();
}
