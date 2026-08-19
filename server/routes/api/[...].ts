import { guestLogin, register, login, platformLogin, verifyToken, getPlayerProfile, updatePlayerStats, getLeaderboard, getPlayerRank, getBalance, addGems, spendGems, addGold, spendGold, getTransactions, addGemsFromXsolla, verifyIAPReceipt, syncBalance, savePlayerArchive, getPlayerArchive, getPlayerSaveVersion, purchasePlayerAsset, exchangeCurrency, checkin, listAnnouncements, createAnnouncement } from '../../utils/database';
import { joinMatchQueue, leaveMatchQueue, checkMatchStatus, submitGameAction, pollGameActions } from '../../utils/database';
import { createSupportTicket, listSupportTickets, closeSupportTicket, prisma } from '../../utils/database';
import { createPaymentToken, verifyWebhookSignature, handleUserValidation, resolveXsollaAmount, GEM_SKU_MAP, validateXsollaUserToken } from '../../utils/xsolla';

/** 客服后台鉴权：x-admin-key 头或 ?key= 查询参数，需配置 SUPPORT_ADMIN_KEY */
function isSupportAdmin(event: any): boolean {
  const key = getQuery(event).key || getRequestHeader(event, 'x-admin-key') || '';
  return !!process.env.SUPPORT_ADMIN_KEY && key === process.env.SUPPORT_ADMIN_KEY;
}

export default defineEventHandler(async (event) => {
  const method = event.method;
  // event.path 在 h3/Nitro 含 query string，先剥离，避免 split('/').pop() 解析 odID 时带上 ?xxx
  const path = event.path.split('?')[0];
  // 请求日志：默认开（测试阶段）；上线后设 LOG_REQUESTS=false 关闭；错误日志始终保留
  if (process.env.LOG_REQUESTS !== 'false') console.log('[API]', method, path);
  
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
      const { email, password, name, referrerId } = await readBody(event);
      if (!email || !password) return { error: '邮箱和密码不能为空' };
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return { error: '邮箱格式不正确' };
      if (password.length < 6) return { error: '密码至少6位' };
      return await register(email, password, name || email.split('@')[0], referrerId);
    }

    if (path === '/api/auth/login' && method === 'POST') {
      const { email, password } = await readBody(event);
      if (!email || !password) return { error: '邮箱和密码不能为空' };
      return await login(email, password);
    }

    // ── Xsolla / 第三方平台登录（邮箱合并） ──
    if (path === '/api/auth/xsolla' && method === 'POST') {
      const { token } = await readBody(event);
      if (!token) return { error: '缺少 token' };
      const xsollaUser = await validateXsollaUserToken(token);
      if (!xsollaUser) return { error: 'Xsolla token 无效或已过期' };
      return await platformLogin({
        platform: 'xsolla',
        platformUserId: xsollaUser.sub,
        email: xsollaUser.email || null,
        name: xsollaUser.name || null,
      });
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
    if (method === 'POST' && path.endsWith('/balance/verify-iap')) {
      const auth = getRequestHeader(event, 'authorization');
      if (!auth?.startsWith('Bearer ')) return { error: 'Unauthorized' };
      const token = verifyToken(auth.slice(7));
      if (!token) return { error: 'Invalid token' };

      const { odID, receipt, productId, transactionId } = await readBody(event);
      if (odID !== token.playerId) return { error: 'Forbidden' };
      return await verifyIAPReceipt(odID, receipt, productId, transactionId);
    }

    if (method === 'POST' && path === '/api/balance/exchange') {
      const auth = getRequestHeader(event, 'authorization');
      if (!auth?.startsWith('Bearer ')) return { error: 'Unauthorized' };
      const token = verifyToken(auth.slice(7));
      if (!token) return { error: 'Invalid token' };
      const { gemsCost, goldReward } = await readBody(event);
      return await exchangeCurrency(token.playerId, Number(gemsCost) || 0, Number(goldReward) || 0);
    }

    if (method === 'POST' && path.endsWith('/balance/sync')) {
      const auth = getRequestHeader(event, 'authorization');
      if (!auth?.startsWith('Bearer ')) return { error: 'Unauthorized' };
      const token = verifyToken(auth.slice(7));
      if (!token) return { error: 'Invalid token' };
      const { odID, gems, gold } = await readBody(event);
      if (odID !== token.playerId) return { error: 'Forbidden' };
      return await syncBalance(odID, Number(gems) || 0, Number(gold) || 0);
    }

    // === 存档云同步（完整资产回滚，跨设备） ===
    if (method === 'PUT' && path.endsWith('/save')) {
      const auth = getRequestHeader(event, 'authorization');
      if (!auth?.startsWith('Bearer ')) return { error: 'Unauthorized' };
      const token = verifyToken(auth.slice(7));
      if (!token) return { error: 'Invalid token' };
      const { odID, save } = await readBody(event);
      if (odID !== token.playerId) return { error: 'Forbidden' };
      return await savePlayerArchive(odID, save);
    }

    if (method === 'POST' && (path === '/api/shop/buy-card' || path === '/api/shop/buy-hero')) {
      const auth = getRequestHeader(event, 'authorization');
      if (!auth?.startsWith('Bearer ')) return { error: 'Unauthorized' };
      const token = verifyToken(auth.slice(7));
      if (!token) return { error: 'Invalid token' };
      const { assetId, cost, currency } = await readBody(event);
      if (!assetId || typeof assetId !== 'string') return { error: 'assetId required' };
      return await purchasePlayerAsset(token.playerId, path.endsWith('/buy-hero') ? 'hero' : 'card', assetId, Number(cost) || 0, currency === 'gem' ? 'gem' : 'gold');
    }

    if (method === 'GET' && path === '/api/save/version') {
      const auth = getRequestHeader(event, 'authorization');
      if (!auth?.startsWith('Bearer ')) return { error: 'Unauthorized' };
      const token = verifyToken(auth.slice(7));
      if (!token) return { error: 'Invalid token' };
      return await getPlayerSaveVersion(token.playerId);
    }

    if (method === 'GET' && path.endsWith('/save')) {
      const auth = getRequestHeader(event, 'authorization');
      if (!auth?.startsWith('Bearer ')) return { error: 'Unauthorized' };
      const token = verifyToken(auth.slice(7));
      if (!token) return { error: 'Invalid token' };
      return await getPlayerArchive(token.playerId);
    }

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
      const days = Number(getQuery(event).days) || 0;
      return await getTransactions(odID, Math.min(Math.max(days, 0), 3650));
    }

    // === 客服工单 ===
    if (method === 'POST' && path === '/api/support/tickets') {
      const auth = getRequestHeader(event, 'authorization');
      if (!auth?.startsWith('Bearer ')) return { error: 'Unauthorized' };
      const token = verifyToken(auth.slice(7));
      if (!token) return { error: 'Invalid token' };
      const { message, category, contact, platform } = await readBody(event);
      if (!message || typeof message !== 'string' || message.trim().length === 0) return { error: 'message required' };
      if (message.length > 2000) return { error: 'message too long' };
      return await createSupportTicket(token.playerId, {
        message: message.trim(),
        category: typeof category === 'string' ? category : undefined,
        contact: typeof contact === 'string' ? contact : undefined,
        platform: typeof platform === 'string' ? platform : undefined,
      });
    }

    if (method === 'GET' && path === '/api/support/tickets') {
      if (!isSupportAdmin(event)) { setResponseStatus(event, 403); return { error: 'Forbidden' }; }
      return await listSupportTickets(getQuery(event).status as string | undefined);
    }

    if (method === 'POST' && path.includes('/support/tickets/') && path.endsWith('/close')) {
      if (!isSupportAdmin(event)) { setResponseStatus(event, 403); return { error: 'Forbidden' }; }
      return await closeSupportTicket(path.split('/').pop()!);
    }

    // === Xsolla 支付 ===
    // 查询该玩家在指定时间后是否有 Xsolla 入账记录（webhook 校验+发钻成功的直接结果）
    if (path.startsWith('/api/payment/recent/') && method === 'GET') {
      const odID = path.split('/').pop()!;
      const after = Number(getQuery(event).after) || 0;
      const txn = await prisma.transaction.findFirst({
        where: {
          playerId: odID,
          detail: 'Xsolla购买',
          createdAt: { gt: new Date(after) },
        },
        orderBy: { createdAt: 'desc' },
      });
      return {
        credited: !!txn,
        amount: txn?.amount ?? 0,
        createdAt: txn?.createdAt ?? null,
      };
    }

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
      if (!rawBody) {
        setResponseStatus(event, 400);
        return { error: 'Empty body' };
      }

      const sig = getRequestHeader(event, 'authorization') || '';
      const sigOk = verifyWebhookSignature(rawBody, sig);
      console.log('[Xsolla][webhook]', 'notification=', rawBody.slice(0, 60), 'sigOk=', sigOk);
      if (!sigOk) {
        console.error('[Xsolla][webhook] INVALID_SIGNATURE from', sig.slice(0, 24), '...');
        setResponseStatus(event, 400);
        return { error: { code: 'INVALID_SIGNATURE', message: 'Signature mismatch' } };
      }

      const data = JSON.parse(rawBody);
      const nt = data.notification_type;
      console.log('[Xsolla][webhook] type=', nt, 'user=', data.user?.id?.value ?? data.user?.id ?? data.user?.external_id, 'payload=', JSON.stringify(data).slice(0, 1200));

      if (nt === 'user_validation') {
        const result = await handleUserValidation(data, (id) => getPlayerProfile(id));
        setResponseStatus(event, result.status);
        return result.body;
      }

      if (nt === 'order_paid' || nt === 'payment') {
        const odID = data.user?.id?.value ?? data.user?.id ?? data.user?.external_id;
        const txnId = String(data.transaction?.id ?? data.billing?.transaction?.id ?? data.notification_id);
        if (!txnId || txnId === 'undefined') {
          console.error('[Xsolla][order_paid] missing transaction id, return 500 for retry');
          setResponseStatus(event, 500);
          return { error: 'Missing transaction id' };
        }

        // 套餐模式：商店已售数量优先；目录模式：SKU 映射
        const amount = resolveXsollaAmount(data);
        if (!odID || amount <= 0) {
          // 解析失败不允许静默 204（Xsolla 不会重试 → 钻石永久丢失）：返回 500 触发重试并留完整日志
          console.error('[Xsolla][order_paid] PARSE_FAILED', 'odID=', odID, 'amount=', amount, 'txn=', txnId, 'payload=', JSON.stringify(data));
          setResponseStatus(event, 500);
          return { error: 'cannot resolve odID or amount' };
        }
        // 同步处理：失败返回 500，Xsolla 会重试；成功返回 204
        try {
          const result = await addGemsFromXsolla(odID, amount, txnId);
          console.log('[Xsolla][order_paid]', 'odID=', odID, 'amount=', amount, 'txn=', txnId, 'result=', JSON.stringify(result));
          if ('error' in result && result.error) {
            console.error('[Xsolla] addGems error:', result.error);
            setResponseStatus(event, 500);
            return { error: result.error };
          }
        } catch (e: any) {
          console.error('[Xsolla] addGems exception:', e);
          setResponseStatus(event, 500);
          return { error: 'internal error' };
        }
      }

      // Xsolla 推荐立即返回 204
      setResponseStatus(event, 204);
      return;
    }

    // ── 每日打卡（需登录） ──
    if (path === '/api/checkin' && method === 'POST') {
      const auth = getRequestHeader(event, 'authorization');
      if (!auth || !auth.startsWith('Bearer ')) return { error: 'Unauthorized' };
      const token = verifyToken(auth.slice(7));
      return await checkin(token.playerId);
    }

    // ── 系统公告（公开，按语言返回） ──
    if (path === '/api/announcements' && method === 'GET') {
      const lang = getQuery(event).lang as string | undefined;
      return await listAnnouncements(lang && lang.length <= 16 ? lang : 'zh');
    }

    // ── 后台管理：新增公告（x-admin-key 头 / ?key= 鉴权） ──────────
    if (path === '/api/admin/announcements' && method === 'POST') {
      if (!isSupportAdmin(event)) {
        throw createError({ statusCode: 403, message: 'Forbidden' });
      }
      const body = await readBody(event);
      return await createAnnouncement(body);
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
