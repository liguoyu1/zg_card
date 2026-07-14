import { createHash, timingSafeEqual } from 'node:crypto';

// ─── 环境变量 ───
const MERCHANT_ID = process.env.XSOLLA_MERCHANT_ID || '';
const API_KEY = process.env.XSOLLA_API_KEY || '';
const PROJECT_ID = process.env.XSOLLA_PROJECT_ID || '';
const WEBHOOK_SECRET = process.env.XSOLLA_WEBHOOK_SECRET || '';

const XSOLLA_API = 'https://api.xsolla.com';
const XSOLLA_PAYSTATION = 'https://secure.xsolla.com/paystation4';

// SKU → 钻石数量
export const GEM_SKU_MAP: Record<string, number> = {
  gem_60: 60,
  gem_300: 300,
  gem_600: 600,
  gem_1500: 1500,
  gem_3000: 3000,
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

    return { url: `${XSOLLA_PAYSTATION}/?token=${data.token}` };
  } catch (e: any) {
    return { error: e.message || 'Failed to create payment token' };
  }
}

/** 验证 Xsolla webhook 签名 */
export function verifyWebhookSignature(rawBody: string, signatureHeader: string): boolean {
  if (!WEBHOOK_SECRET) return false;

  // header 格式: "Signature <value>"
  const received = signatureHeader.replace(/^Signature\s+/i, '').trim();
  if (!received) return false;

  const computed = createHash('sha1')
    .update(rawBody + WEBHOOK_SECRET)
    .digest('hex')
    .toLowerCase();

  // 常量时间比较防时序攻击
  const bufA = Buffer.from(computed);
  const bufB = Buffer.from(received.toLowerCase());
  if (bufA.length !== bufB.length) return false;
  return timingSafeEqual(bufA, bufB);
}
