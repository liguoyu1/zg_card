import { createHash, createHmac, timingSafeEqual } from 'node:crypto';

// ─── 环境变量 ───
const MERCHANT_ID = process.env.XSOLLA_MERCHANT_ID || '';
const API_KEY = process.env.XSOLLA_API_KEY || '';
const PROJECT_ID = process.env.XSOLLA_PROJECT_ID || '';
// Login 验证用 UUID（数字支付 project_id 不适用于 Login API）
const LOGIN_PROJECT_ID = process.env.XSOLLA_LOGIN_PROJECT_ID || PROJECT_ID;
const webhookSecret = () => process.env.XSOLLA_WEBHOOK_SECRET || '';

const XSOLLA_API = 'https://api.xsolla.com';
const XSOLLA_STORE = 'https://store.xsolla.com/api';
const XSOLLA_PAYSTATION = 'https://secure.xsolla.com/paystation4';
const XSOLLA_PAYSTATION_SANDBOX = 'https://sandbox-secure.xsolla.com/paystation4';
const XSOLLA_LOGIN_VALIDATE = 'https://login.xsolla.com/api/oauth2/token/validate';

// ─── Xsolla Login（OAuth 登录）───
// 验证用户 JWT（客户端登录成功后回调携带的 access token）。
// 返回 Xsolla 账号信息：sub（用户 ID）、email、name；失败返回 null。
export async function validateXsollaUserToken(token: string): Promise<{
  sub: string;
  email?: string;
  name?: string;
} | null> {
  if (!token || !PROJECT_ID) return null;
  try {
    const resp = await fetch(
      `${XSOLLA_LOGIN_VALIDATE}?projectId=${encodeURIComponent(LOGIN_PROJECT_ID)}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token }),
      },
    );
    let body: Record<string, unknown> = {};
    try { body = (await resp.json()) as Record<string, unknown>; } catch { /* ignore */ }
    if (resp.status !== 200) return null;
    // Xsolla 返回体含 auth_info.user.id / user.id 等结构，采样兼容性解析
    const auth = body['auth_info'] ?? body;
    const user =
      typeof auth === 'object' && auth !== null && 'user' in auth
        ? (auth as { user: unknown }).user
        : auth;
    const u = (typeof user === 'object' && user !== null ? user : {}) as Record<string, unknown>;
    const sub = String(u['id'] ?? body['sub'] ?? '');
    if (!sub) return null;
    return {
      sub,
      email: typeof u['email'] === 'string' ? u['email'] : undefined,
      name: typeof u['name'] === 'string' ? u['name'] : undefined,
    };
  } catch {
    return null;
  }
}

// SKU → 钻石数量（Xsolla 专属：活动赠予 +20%）
// 以各档位总额（如 gem_300 → 350）为基准新增 20% 活动钻（如 420），平台手续费仍低于 IAP
export const GEM_SKU_MAP: Record<string, number> = {
  gem_60: 72,
  gem_300: 420,
  gem_600: 900,
  gem_1500: 2400,
  gem_3000: 5400,
};

/** 创建 Xsolla 支付令牌 → 返回 PayStation URL */
export async function createPaymentToken(
  odID: string,
  sku: string,
  userName?: string,
  userEmail?: string,
): Promise<{ url: string } | { error: string }> {
  if (!MERCHANT_ID || !API_KEY) {
    return { error: 'Xsolla not configured' };
  }
  if (!GEM_SKU_MAP[sku]) {
    return { error: 'Invalid SKU' };
  }

  try {
    const auth = Buffer.from(`${MERCHANT_ID}:${API_KEY}`).toString('base64');
    const resp = await fetch(`${XSOLLA_API}/merchant/v2/merchants/${MERCHANT_ID}/token`, {
      method: 'POST',
      headers: {
        Authorization: `Basic ${auth}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        settings: {
          project_id: Number(PROJECT_ID),
          currency: 'USD',
          language: 'zh',
          // 官方设置：关闭"自定义数量"输入框，PayStation 展示虚拟货币套餐
          ui: {
            components: {
              virtual_currency: {
                custom_amount: false,
              },
            },
          },
        },
        user: {
          id: { value: odID },
          name: { value: userName || odID },
          ...(userEmail ? { email: { value: userEmail } } : {}),
        },
      }),
    });

    const data = await resp.json();
    if (!resp.ok) {
      return { error: data.message || `Xsolla API error: ${resp.status}` };
    }

    // 官方流程：先取用户 token，再创建带商品的订单，拿到支付 token
    const sandbox = process.env.XSOLLA_SANDBOX !== 'false';
    const orderResp = await fetch(
      `${XSOLLA_STORE}/v2/project/${PROJECT_ID}/payment/item/${sku}`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${data.token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          quantity: 1,
          sandbox,
          settings: {
            return_url: process.env.XSOLLA_RETURN_URL || 'https://wscard.games',
            redirect_policy: {
              redirect_conditions: 'successful',
              delay: 5,
              status_for_manual_redirection: 'successful_or_canceled',
              redirect_button_caption: '返回游戏',
            },
            ui: {
              components: {
                virtual_currency: { custom_amount: false },
              },
            },
          },
        }),
      },
    );
    const order = await orderResp.json();
    if (!orderResp.ok || !order.token) {
      return { error: order.errorMessage || order.message || `Xsolla order error: ${orderResp.status}` };
    }

    const paystation = sandbox ? XSOLLA_PAYSTATION_SANDBOX : XSOLLA_PAYSTATION;
    return { url: `${paystation}/?token=${order.token}` };
  } catch (e: any) {
    return { error: e.message || 'Failed to create payment token' };
  }
}

/** 处理 Xsolla user_validation webhook：校验用户是否在游戏内注册
 * 返回 200 { user: { id } } 视为有效；404 用户不存在；400 缺少 user.id */
export async function handleUserValidation(
  data: any,
  findUser: (id: string) => Promise<unknown>,
): Promise<{ status: number; body: Record<string, unknown> }> {
  // Xsolla user_validation 的 user.id 是对象 { value, type }，必须解包 value 再查库
  const raw = data?.user?.id?.value ?? data?.user?.id;
  const uid = typeof raw === 'object' ? raw?.value : raw;
  if (uid === undefined || uid === null || String(uid) === '') {
    return { status: 400, body: { error: 'Missing user id' } };
  }
  const user = await findUser(String(uid));
  if (!user) return { status: 404, body: { error: 'User not found' } };
  return { status: 200, body: { user: { id: String(uid) } } };
}

/** 从 order_paid/payment webhook 解析应发放的钻石数
 * 仅按 SKU 映射发钻 = 套餐钻石 + 活动赠送（与 iOS IAP_GEM_MAP 同表，如 gem_300 → 350）；
 * 无 SKU 返回 0，不发钻 */
export function resolveXsollaAmount(data: any): number {
  const vc = data?.purchase?.virtual_currency ?? {};
  const item = data?.items?.[0] ?? {};
  const sku = vc.sku ?? item.sku;
  if (sku && GEM_SKU_MAP[sku]) return GEM_SKU_MAP[sku];
  // 套餐订单 items 可能用通用货币 SKU（如 gem）+ 数量：按数量发钻
  return Number(vc.quantity ?? item.quantity ?? item.amount) > 0
    ? Number(vc.quantity ?? item.quantity ?? item.amount)
    : 0;
}

/** 验证 Xsolla webhook 签名（header: Authorization: Signature <hex>）
 * 官方算法：sha1(body + secret)，兼容历史 HMAC-SHA1 */
export function verifyWebhookSignature(rawBody: string, signatureHeader: string): boolean {
  const secret = webhookSecret();
  if (!secret) return false;

  // header 格式: "Signature <value>"
  const received = signatureHeader.replace(/^Signature\s+/i, '').trim().toLowerCase();
  if (!received) return false;

  const candidates = [
    createHash('sha1').update(rawBody + secret).digest('hex'),
    createHmac('sha1', secret).update(rawBody).digest('hex'),
  ].filter((c) => c.length === received.length);

  // 常量时间比较防时序攻击
  const bufB = Buffer.from(received);
  return candidates.some((c) => timingSafeEqual(Buffer.from(c), bufB));
}
