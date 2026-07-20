import { prisma, createToken, verifyToken, calculateRank, getRankName } from '../utils/database';
import { H3Event } from 'h3';

// 游客登录
export async function guestLogin(event: H3Event) {
  const body = await readBody(event);
  const deviceId = body?.deviceId || crypto.randomUUID();
  
  // 查找或创建玩家
  let player = await prisma.player.findFirst({
    where: { guestToken: deviceId },
  });
  
  if (!player) {
    player = await prisma.player.create({
      data: {
        guestToken: deviceId,
        name: `玩家${Math.floor(Math.random() * 9999)}`,
      },
    });
    
    // 初始化收藏
    await prisma.collection.create({
      data: { playerId: player.id, cards: [] },
    });
    
    // 生成每日任务
    await generateDailyQuests(player.id);
  }
  
  const token = createToken({ playerId: player.id, guestToken: deviceId });
  
  return {
    success: true,
    data: {
      token,
      player: {
        id: player.id,
        name: player.name,
        rank: player.rank,
        elo: player.elo,
        wins: player.wins,
        losses: player.losses,
      },
    },
  };
}

// 获取玩家信息
export async function getPlayerProfile(event: H3Event) {
  const auth = event.context.auth as { playerId: string };
  if (!auth) {
    throw createError({ statusCode: 401, message: 'Unauthorized' });
  }
  
  const player = await prisma.player.findUnique({
    where: { id: auth.playerId },
    include: {
      decks: { orderBy: { createdAt: 'desc' } },
      quests: { where: { claimed: false } },
    },
  });
  
  if (!player) {
    throw createError({ statusCode: 404, message: 'Player not found' });
  }
  
  return {
    success: true,
    data: {
      id: player.id,
      name: player.name,
      avatar: player.avatar,
      rank: player.rank,
      rankName: getRankName(player.rank),
      elo: player.elo,
      wins: player.wins,
      losses: player.losses,
      decks: player.decks.map(d => ({
        id: d.id,
        name: d.name,
        heroId: d.heroId,
        cardCount: d.cards.length,
        isActive: d.isActive,
      })),
      activeQuests: player.quests,
    },
  };
}

// 更新玩家信息
export async function updatePlayerProfile(event: H3Event) {
  const auth = event.context.auth as { playerId: string };
  if (!auth) {
    throw createError({ statusCode: 401, message: 'Unauthorized' });
  }
  
  const body = await readBody(event);
  const { name, avatar } = body;
  
  const player = await prisma.player.update({
    where: { id: auth.playerId },
    data: { name, avatar },
  });
  
  return { success: true, data: { name: player.name, avatar: player.avatar } };
}

// 生成每日任务
async function generateDailyQuests(playerId: string) {
  const dailyQuests = [
    { questType: 'win', target: 3, reward: 100 },
    { questType: 'play', target: 5, reward: 50 },
  ];
  
  const weeklyQuests = [
    { questType: 'win', target: 15, reward: 500 },
    { questType: 'play', target: 30, reward: 300 },
  ];
  
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(4, 0, 0, 0); // 每天凌晨4点重置
  
  const nextWeek = new Date();
  nextWeek.setDate(nextWeek.getDate() + 7);
  
  for (const quest of dailyQuests) {
    await prisma.quest.create({
      data: {
        playerId,
        type: 'daily',
        questType: quest.questType,
        target: quest.target,
        reward: quest.reward,
        expiresAt: tomorrow,
      },
    });
  }
  
  for (const quest of weeklyQuests) {
    await prisma.quest.create({
      data: {
        playerId,
        type: 'weekly',
        questType: quest.questType,
        target: quest.target,
        reward: quest.reward,
        expiresAt: nextWeek,
      },
    });
  }
}

// 认证中间件
export function authMiddleware(event: H3Event) {
  const authHeader = getHeader(event, 'authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    throw createError({ statusCode: 401, message: 'Missing token' });
  }
  
  const token = authHeader.slice(7);
  const payload = verifyToken(token);
  if (!payload) {
    throw createError({ statusCode: 401, message: 'Invalid token' });
  }
  
  event.context.auth = payload;
}