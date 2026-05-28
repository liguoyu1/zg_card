import { guestLogin, verifyToken, getPlayerProfile, updatePlayerStats, getLeaderboard, getPlayerRank } from '../../utils/database';
import { joinMatchQueue, leaveMatchQueue, checkMatchStatus } from '../../utils/database';

export default defineEventHandler(async (event) => {
  const method = event.method;
  const path = event.path;
  
  setResponseHeaders(event, {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  });
  
  if (method === 'OPTIONS') {
    return { status: 'ok' };
  }
  
  try {
    if (path === '/api/auth/guest' && method === 'POST') {
      const body = await readBody(event);
      return await guestLogin(body.name || `玩家${Date.now() % 10000}`);
    }
    
    if (path.startsWith('/api/player/') && method === 'GET') {
      const odID = path.split('/').pop()!;
      return await getPlayerProfile(odID) || { error: 'Player not found' };
    }
    
    if (path === '/api/player/update-stats' && method === 'POST') {
      const { odID, won, opponentRating } = await readBody(event);
      return await updatePlayerStats(odID, won, opponentRating);
    }
    
    if (path === '/api/leaderboard' && method === 'GET') {
      const limit = parseInt(getQuery(event).limit as string) || 100;
      return await getLeaderboard(limit);
    }
    
    if (path.startsWith('/api/rank/') && method === 'GET') {
      const odID = path.split('/').pop()!;
      return { odID, rank: await getPlayerRank(odID) };
    }
    
    if (path === '/api/match/join' && method === 'POST') {
      const body = await readBody(event);
      return await joinMatchQueue({
        odID: body.odID,
        odName: body.odName,
        odHeroId: body.odHeroId,
        rating: body.rating || 1000,
      });
    }
    
    if (path === '/api/match/leave' && method === 'POST') {
      const { odID } = await readBody(event);
      await leaveMatchQueue(odID);
      return { success: true };
    }
    
    if (path === '/api/match/check' && method === 'POST') {
      const { odID, odHeroId, rating } = await readBody(event);
      return await checkMatchStatus(odID, odHeroId, rating);
    }
    
    // Health
    if (path === '/api/health' && method === 'GET') {
      return { status: 'ok', timestamp: new Date().toISOString() };
    }
    
    return { error: 'Not found', path, method };
  } catch (e: any) {
    console.error('API error:', e);
    return { error: e.message || 'Internal error' };
  }
});