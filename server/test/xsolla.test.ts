import { createHash, createHmac } from 'node:crypto';
import assert from 'node:assert/strict';
import { verifyWebhookSignature, handleUserValidation, resolveXsollaAmount, GEM_SKU_MAP } from '../utils/xsolla.ts';
import { IAP_GEM_MAP } from '../utils/apple_iap.ts';

const SECRET = 'test-webhook-secret';
process.env.XSOLLA_WEBHOOK_SECRET = SECRET;

const body = JSON.stringify({ notification_type: 'order_paid', user: { id: 'u1' } });
const hmac = (s: string, b: string) => createHmac('sha1', s).update(b).digest('hex');
const concatSha1 = (s: string, b: string) => createHash('sha1').update(b + s).digest('hex');

assert.equal(verifyWebhookSignature(body, `Signature ${hmac(SECRET, body)}`), true, 'valid HMAC should pass');
assert.equal(verifyWebhookSignature(body, `Signature ${concatSha1(SECRET, body)}`), true, 'valid concat sha1 should pass');
assert.equal(verifyWebhookSignature(body, `Signature ${hmac('wrong-secret', body)}`), false, 'wrong secret should fail');
assert.equal(verifyWebhookSignature(body, 'Signature deadbeef'), false, 'tampered body should fail');
assert.equal(verifyWebhookSignature(body, ''), false, 'missing header should fail');
assert.equal(verifyWebhookSignature(body, `Signature ${hmac(SECRET, body + 'x')}`), false, 'replay with extra body should fail');

const findUser = async (id: string) => (id === 'u1' ? { id } : null);
assert.deepEqual(
  await handleUserValidation({ user: { id: 'u1' } }, findUser),
  { status: 200, body: { user: { id: 'u1' } } },
  'existing user should return 200 with user id',
);
assert.equal((await handleUserValidation({ user: { id: 'ghost' } }, findUser)).status, 404, 'unknown user should return 404');
assert.equal((await handleUserValidation({}, findUser)).status, 400, 'missing user id should return 400');

assert.equal(resolveXsollaAmount({ items: [{ sku: 'gem_300', quantity: 300 }] }), 420, 'gem_300 = 套餐300 + 20%活动 = 350 × 1.2 = 420');
assert.equal(resolveXsollaAmount({ purchase: { virtual_currency: { sku: 'gem_300', quantity: 300 } } }), 420, 'sku wins over package quantity');
assert.equal(resolveXsollaAmount({ items: [{ sku: 'gem', type: 'virtual_currency', quantity: 300 }] }), 300, 'generic currency sku: grant by quantity');
assert.equal(resolveXsollaAmount({ purchase: { virtual_currency: { quantity: 300 } } }), 300, 'quantity-only: grant by quantity');
assert.equal(resolveXsollaAmount({}), 0, 'no purchase info should grant 0');

// Xsolla 渠道有意在 iOS 基准档位上新增 20% 活动钻（见 GEM_SKU_MAP 注释），
// 因此两表不应强相等；改为校验 Xsolla = round(iOS × 1.2) 的映射关系。
for (const [sku, iapValue] of Object.entries(IAP_GEM_MAP)) {
  assert.equal(GEM_SKU_MAP[sku], Math.round(iapValue * 1.2),
    `Xsolla ${sku} should be 120% of iOS ${sku} (${iapValue} -> ${Math.round(iapValue * 1.2)})`);
}
console.log('ALL_XSOLLA_TESTS_PASS');
