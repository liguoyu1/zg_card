import { guestLogin, verifyToken, getPlayerProfile, updatePlayerStats, getLeaderboard, getPlayerRank } from '../utils/database';
import { joinMatchQueue, leaveMatchQueue, checkMatchStatus } from '../utils/database';

export default defineEventHandler(async (event) => {
  const method = event.method;
  const path = event.path;
  
  // CORS头
  setResponseHeaders(event, {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  });
  
  if (method === 'OPTIONS') {
    return { status: 'ok' };
  }
  
  try {
    // ==================== 认证 ====================
    
    if (path === '/api/auth/guest' && method === 'POST') {
      const body = await readBody(event);
      const result = await guestLogin(body.odName || `玩家${Date.now() % 10000}`);
      return result;
    }
    
    // ==================== 玩家 ====================
    
    if (path.startsWith('/api/player/') && method === 'GET') {
      const odID = path.split('/').pop()!;
      const profile = await getPlayerProfile(odID);
      return profile || { error: 'Player not found' };
    }
    
    if (path === '/api/player/update-stats' && method === 'POST') {
      const body = await readBody(event);
      const { odID, won, opponentRating } = body;
      const result = await updatePlayerStats(odID, won, opponentRating);
      return result;
    }
    
    // ==================== 排行榜 ====================
    
    if (path === '/api/leaderboard' && method === 'GET') {
      const limit = parseInt(getQuery(event).limit as string) || 100;
      const leaderboard = await getLeaderboard(limit);
      return leaderboard;
    }
    
    if (path.startsWith('/api/rank/') && method === 'GET') {
      const odID = path.split('/').pop()!;
      const rank = await getPlayerRank(odID);
      return { odID, rank };
    }
    
    // ==================== 匹配 ====================
    
    if (path === '/api/match/join' && method === 'POST') {
      const body = await readBody(event);
      const result = await joinMatchQueue({
        odID: body.odID,
        odName: body.odName,
        odHeroId: body.odHeroId,
        rating: body.rating || 1000,
        joinedAt: new Date(),
      });
      return result;
    }
    
    if (path === '/api/match/leave' && method === 'POST') {
      const body = await readBody(event);
      await leaveMatchQueue(body.odID);
      return { success: true };
    }
    
    if (path === '/api/match/check' && method === 'POST') {
      const body = await readBody(event);
      const result = await checkMatchStatus(body.odID, body.odHeroId, body.rating);
      return result;
    }
    
    // ==================== 健康检查 ====================
    
    if (path === '/api/health' && method === 'GET') {
      return { 
        status: 'ok', 
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
      };
    }
    
    return { error: 'Not found', path, method };
  } catch (e: any) {
    console.error('API error:', e);
    return { error: e.message || 'Internal error' };
  }
});