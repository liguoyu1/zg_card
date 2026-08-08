import { createHmac } from 'node:crypto';
import assert from 'node:assert/strict';
import { verifyWebhookSignature, GEM_SKU_MAP } from '../utils/xsolla.ts';
import { IAP_GEM_MAP } from '../utils/apple_iap.ts';

const SECRET = 'test-webhook-secret';
process.env.XSOLLA_WEBHOOK_SECRET = SECRET;

const body = JSON.stringify({ notification_type: 'order_paid', user: { id: 'u1' } });
const hmac = (s: string, b: string) => createHmac('sha1', s).update(b).digest('hex');

assert.equal(verifyWebhookSignature(body, `Signature ${hmac(SECRET, body)}`), true, 'valid HMAC should pass');
assert.equal(verifyWebhookSignature(body, `Signature ${hmac('wrong-secret', body)}`), false, 'wrong secret should fail');
assert.equal(verifyWebhookSignature(body, 'Signature deadbeef'), false, 'tampered body should fail');
assert.equal(verifyWebhookSignature(body, ''), false, 'missing header should fail');
assert.equal(verifyWebhookSignature(body, `Signature ${hmac(SECRET, body + 'x')}`), false, 'replay with extra body should fail');

assert.deepEqual(GEM_SKU_MAP, IAP_GEM_MAP, 'Xsolla SKU map must match iOS IAP map');
console.log('ALL_XSOLLA_TESTS_PASS');
