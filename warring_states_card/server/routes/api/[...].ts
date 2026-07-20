import { guestLogin, register, login, verifyToken, getPlayerProfile, updatePlayerStats, getLeaderboard, getPlayerRank, getBalance, addGems, spendGems, addGold, spendGold, getTransactions, addGemsFromXsolla, verifyIapApple } from '../../utils/database';
import { joinMatchQueue, leaveMatchQueue, checkMatchStatus, submitGameAction, pollGameActions } from '../../utils/database';
import { createPaymentToken, verifyWebhookSignature, GEM_SKU_MAP } from '../../utils/xsolla';

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
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return { error: '邮箱格式不正确' };
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

    // === Apple IAP 收据验证 ===
    if (path === '/api/balance/verify-iap' && method === 'POST') {
      const auth = getRequestHeader(event, 'authorization');
      if (!auth?.startsWith('Bearer ')) return { error: 'Unauthorized' };
      const payload = verifyToken(auth.slice(7));
      if (!payload) return { error: 'Invalid token' };

      const { receipt, productId, transactionId } = await readBody(event);
      if (!receipt || !productId) return { error: 'Missing receipt or productId' };

      return await verifyIapApple(payload.playerId, receipt, productId, transactionId || '');
    }

    // === Xsolla 支付 ===
    if (path === '/api/payment/create-token' && method === 'POST') {
      const auth = getRequestHeader(event, 'authorization');
      if (!auth?.startsWith('Bearer ')) return { error: 'Unauthorized' };
      const token = verifyToken(auth.slice(7));
      if (!token) return { error: 'Invalid token' };

      const { sku } = await readBody(event);
      if (!GEM_SKU_MAP[sku]) return { error: 'Invalid SKU' };

      const player = await getPlayerProfile(token.playerId);
      if (!(player as any)?.email) return { error: 'Registered email account required' };
      const result = await createPaymentToken(token.playerId, sku, (player as any)?.name, (player as any).email);
      return result;
    }

    if (path === '/api/payment/webhook' && method === 'POST') {
      const rawBody = await readRawBody(event);
      if (!rawBody) return { error: 'Empty body' };

      const sig = getRequestHeader(event, 'authorization') || '';
      if (!verifyWebhookSignature(rawBody, sig)) {
        return { error: { code: 'INVALID_SIGNATURE', message: 'Signature mismatch' } };
      }

      const data = JSON.parse(rawBody);
      const nt = data.notification_type;

      if (nt === 'order_paid' || nt === 'payment') {
        const odID = data.user?.id;
        const sku = data.purchase?.virtual_currency?.sku;
        const txnId = data.transaction?.id || data.notification_id;

        if (odID && sku && GEM_SKU_MAP[sku]) {
          const amount = GEM_SKU_MAP[sku];
          // 异步处理，先返回 204
          addGemsFromXsolla(odID, amount, txnId).catch(e =>
            console.error('[Xsolla] addGems error:', e)
          );
        }
      }

      // Xsolla 推荐立即返回 204
      setResponseStatus(event, 204);
      return;
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