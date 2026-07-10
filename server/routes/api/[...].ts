import { guestLogin, register, login, verifyToken, getPlayerProfile, updatePlayerStats, getLeaderboard, getPlayerRank, getBalance, addGems, spendGems, addGold, spendGold, getTransactions } from '../../utils/database';
import { joinMatchQueue, leaveMatchQueue, checkMatchStatus, submitGameAction, pollGameActions } from '../../utils/database';

export default defineEventHandler(async (event) => {
  const method = event.method;
  const path = event.path;
  console.log('[API]', method, path);
  
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

    if (path === '/api/auth/register' && method === 'POST') {
      const { email, password, name } = await readBody(event);
      if (!email || !password) return { error: '邮箱和密码不能为空' };
      if (password.length < 6) return { error: '密码至少6位' };
      return await register(email, password, name || email.split('@')[0]);
    }

    if (path === '/api/auth/login' && method === 'POST') {
      const { email, password } = await readBody(event);
      if (!email || !password) return { error: '邮箱和密码不能为空' };
      return await login(email, password);
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
    
    // Game actions
    if (method === 'POST' && path.endsWith('/game/submit-action')) {
      const body = await readBody(event);
      return await submitGameAction(body.matchId, body.odID, body.seq, body.action);
    }

    if (method === 'POST' && path.endsWith('/game/poll-actions')) {
      const body = await readBody(event);
      return await pollGameActions(body.matchId, body.after || 0);
    }

    // === 资产 ===
    if (method === 'POST' && path.endsWith('/balance/add-gems')) {
      const { odID, amount, detail, receiptId } = await readBody(event);
      return await addGems(odID, amount, detail, receiptId);
    }

    if (method === 'POST' && path.endsWith('/balance/spend-gems')) {
      const { odID, amount, detail } = await readBody(event);
      return await spendGems(odID, amount, detail);
    }

    if (method === 'POST' && path.endsWith('/balance/add-gold')) {
      const { odID, amount, detail } = await readBody(event);
      return await addGold(odID, amount, detail);
    }

    if (method === 'POST' && path.endsWith('/balance/spend-gold')) {
      const { odID, amount, detail } = await readBody(event);
      return await spendGold(odID, amount, detail);
    }

    if (method === 'GET' && path.includes('/balance/get/')) {
      const odID = path.split('/').pop()!;
      return await getBalance(odID);
    }

    if (method === 'GET' && path.includes('/balance/transactions/')) {
      const odID = path.split('/').pop()!;
      return await getTransactions(odID);
    }
    if (path === '/api/health' && method === 'GET') {
      return { status: 'ok', timestamp: new Date().toISOString() };
    }

    if (method === 'POST' && path.endsWith('/game/submit-action')) {
      const body = await readBody(event);
      return await submitGameAction(body.matchId, body.odID, body.seq, body.action);
    }

    if (method === 'POST' && path.endsWith('/game/poll-actions')) {
      const body = await readBody(event);
      return await pollGameActions(body.matchId, body.after || 0);
    }

    console.error('Route not matched:', method, path);
    return { error: 'Not found', path, method };
  } catch (e: any) {
    console.error('API error:', e);
    return { error: e.message || 'Internal error' };
  }
});