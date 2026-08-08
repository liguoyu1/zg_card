// ─── Apple IAP 服务端验证 ───
// 客户端上传 receipt，服务端用 Apple verifyReceipt 校验后按 productId 发放钻石。

import { X509Certificate, verify } from 'node:crypto';

const APPLE_PRODUCTION = 'https://buy.itunes.apple.com/verifyReceipt';
const APPLE_SANDBOX = 'https://sandbox.itunes.apple.com/verifyReceipt';
const APPLE_BUNDLE_ID = process.env.APPLE_BUNDLE_ID || 'com.game.Warringstates';

// Apple Root CA - G3（macOS 系统钥匙串导出，SHA-256 9A30E66217898CBC3FFF23756803BB135C486B62B5D102E89338F39A3043C54F）
const APPLE_ROOT_CA_G3 = `-----BEGIN CERTIFICATE-----
MIICQzCCAcmgAwIBAgIILcX8iNLFS5UwCgYIKoZIzj0EAwMwZzEbMBkGA1UEAwwS
QXBwbGUgUm9vdCBDQSAtIEczMSYwJAYDVQQLDB1BcHBsZSBDZXJ0aWZpY2F0aW9u
IEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwHhcN
MTQwNDMwMTgxOTA2WhcNMzkwNDMwMTgxOTA2WjBnMRswGQYDVQQDDBJBcHBsZSBS
b290IENBIC0gRzMxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9y
aXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzB2MBAGByqGSM49
AgEGBSuBBAAiA2IABJjpLz1AcqTtkyJygRMc3RCV8cWjTnHcFBbZDuWmBSp3ZHtf
TjjTuxxEtX/1H7YyYl3J6YRbTzBPEVoA/VhYDKX1DyxNB0cTddqXl5dvMVztK517
IDvYuVTZXpmkOlEKMaNCMEAwHQYDVR0OBBYEFLuw3qFYM4iapIqZ3r6966/ayySr
MA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMAoGCCqGSM49BAMDA2gA
MGUCMQCD6cHEFl4aXTQY2e3v9GwOAEZLuN+yRhHFD/3meoyhpmvOwgPUnPWTxnS4
at+qIxUCMG1mihDK1A3UT82NQz60imOlM27jbdoXt2QfyFMm+YhidDkLF1vLUagM
6BgD56KyKA==
-----END CERTIFICATE-----`;

// productId → 发放钻石数（基础 + 赠送）
export const IAP_GEM_MAP: Record<string, number> = {
  gem_60: 60,
  gem_300: 350,
  gem_600: 750,
  gem_1500: 2000,
  gem_3000: 4500,
};

interface AppleReceiptInfo {
  productId: string;
  transactionId: string;
  bundleId: string;
}

function isJws(receipt: string): boolean {
  return /^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/.test(receipt);
}

function b64url(input: string): Buffer {
  return Buffer.from(input.replace(/-/g, '+').replace(/_/g, '/'), 'base64');
}

// JWS ES256 签名是 raw r||s（各 32 字节），Node verify 需要 DER 编码
function rawToDer(raw: Buffer): Buffer {
  const enc = (b: Buffer): Buffer => {
    let i = 0;
    while (i < b.length - 1 && b[i] === 0) i++;
    const v = b.subarray(i);
    const out = Buffer.alloc(v[0] & 0x80 ? v.length + 3 : v.length + 2);
    let o = 0;
    out[o++] = 0x02;
    if (v[0] & 0x80) {
      out[o++] = v.length + 1;
      out[o++] = 0;
    } else {
      out[o++] = v.length;
    }
    out.set(v, o);
    return out;
  };
  const r = enc(raw.subarray(0, 32));
  const s = enc(raw.subarray(32));
  const out = Buffer.alloc(2 + r.length + s.length);
  out[0] = 0x30;
  out[1] = r.length + s.length;
  out.set(r, 2);
  out.set(s, 2 + r.length);
  return out;
}

/** StoreKit 2 交易 JWS 验证：ES256 签名 + x5c 证书链到指定根证书 + 交易声明校验 */
export function verifyJws(
  jws: string,
  expectedProductId: string,
  rootPem: string,
): AppleReceiptInfo | { error: string } {
  const parts = jws.split('.');
  if (parts.length !== 3) return { error: 'Malformed JWS' };
  let header: any;
  let payload: any;
  try {
    header = JSON.parse(b64url(parts[0]).toString('utf8'));
    payload = JSON.parse(b64url(parts[1]).toString('utf8'));
  } catch {
    return { error: 'Malformed JWS payload' };
  }
  if (header.alg !== 'ES256' || !Array.isArray(header.x5c) || header.x5c.length === 0) {
    return { error: 'Unsupported JWS' };
  }
  const root = new X509Certificate(rootPem);
  let chain: X509Certificate[] = [];
  try {
    chain = header.x5c.map((c: string) => new X509Certificate(Uint8Array.from(Buffer.from(c, 'base64'))));
  } catch {
    return { error: 'Malformed JWS cert' };
  }
  for (let i = 0; i < chain.length; i++) {
    const issuer = chain[i + 1] ?? root;
    if (chain[i].issuer !== issuer.subject) return { error: 'JWS cert chain broken' };
    if (!chain[i].verify(issuer.publicKey)) return { error: 'JWS cert chain signature invalid' };
  }
  const ok = verify(
    'sha256',
    new TextEncoder().encode(`${parts[0]}.${parts[1]}`),
    chain[0].publicKey,
    rawToDer(b64url(parts[2])) as any,
  );
  if (!ok) return { error: 'JWS signature invalid' };
  if (payload.bundleId !== APPLE_BUNDLE_ID) return { error: 'Apple bundle ID mismatch' };
  if (payload.productId !== expectedProductId) return { error: 'Product mismatch' };
  if (payload.quantity !== 1) return { error: 'Invalid Apple quantity' };
  if (payload.revocationDate) return { error: 'Transaction revoked' };
  return {
    productId: payload.productId,
    transactionId: payload.transactionId,
    bundleId: payload.bundleId,
  };
}

/** StoreKit 2 交易 JWS 验证（信任链锚定 Apple Root CA - G3） */
export function verifyStoreKit2Jws(jws: string, expectedProductId: string): AppleReceiptInfo | { error: string } {
  return verifyJws(jws, expectedProductId, APPLE_ROOT_CA_G3);
}

/** 调用 Apple verifyReceipt，返回最新一笔购买信息 */
export async function verifyAppleReceipt(
  receipt: string,
  expectedProductId?: string,
): Promise<AppleReceiptInfo | { error: string }> {
  if (!receipt) return { error: 'Missing receipt' };
  if (isJws(receipt)) {
    if (!expectedProductId) return { error: 'Missing product' };
    return verifyStoreKit2Jws(receipt, expectedProductId);
  }

  const verify = async (url: string) => {
    const resp = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 'receipt-data': receipt, password: process.env.APPLE_SHARED_SECRET || '' }),
    });
    if (!resp.ok) throw new Error(`Apple verify HTTP ${resp.status}`);
    return resp.json();
  };

  let data: any;
  try {
    data = await verify(APPLE_PRODUCTION);
  } catch (e: any) {
    return { error: e.message || 'Apple verify failed' };
  }

  // 21007 = sandbox receipt 发到了生产环境 → 重试 sandbox
  if (data.status === 21007) {
    try {
      data = await verify(APPLE_SANDBOX);
    } catch (e: any) {
      return { error: e.message || 'Apple sandbox verify failed' };
    }
  }

  if (data.status !== 0) {
    return { error: `Apple verify status ${data.status}` };
  }
  if (data.receipt?.bundle_id && data.receipt.bundle_id !== APPLE_BUNDLE_ID) {
    return { error: 'Apple bundle ID mismatch' };
  }

  const transactions = [...(data.latest_receipt_info ?? []), ...(data.receipt?.in_app ?? [])];
  const latest = transactions.sort((a: any, b: any) =>
    Number(b.purchase_date_ms || 0) - Number(a.purchase_date_ms || 0),
  )[0];
  if (!latest) return { error: 'No purchase found in receipt' };

  return {
    productId: latest.product_id,
    transactionId: latest.transaction_id,
    bundleId: data.receipt?.bundle_id || '',
  };
}
