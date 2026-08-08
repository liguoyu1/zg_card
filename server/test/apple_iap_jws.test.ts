import { execSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { sign } from 'node:crypto';
import { verifyJws, verifyStoreKit2Jws } from '../utils/apple_iap.ts';
import assert from 'node:assert/strict';

const dir = mkdtempSync(join(tmpdir(), 'iap-test-'));
const run = (cmd: string) => execSync(cmd, { stdio: 'pipe' }).toString();
const cert = (name: string) => readFileSync(join(dir, name), 'utf8');
const derB64 = (name: string) => {
  run(`openssl x509 -in ${join(dir, name)} -outform DER -out ${join(dir, name + '.der')}`);
  return readFileSync(join(dir, name + '.der')).toString('base64');
};

try {
  const g = (n: string) => `openssl ecparam -name prime256v1 -genkey -noout -out ${join(dir, n)}`;
  const req = (key: string, subj: string, out: string) =>
    `openssl req -new -key ${join(dir, key)} -subj "${subj}" -out ${join(dir, out)}`;
  run(g('root.key'));
  run(`openssl req -x509 -new -key ${join(dir, 'root.key')} -subj "/CN=Test Apple Root" -days 3650 -out ${join(dir, 'root.pem')}`);
  run(g('mid.key'));
  run(req('mid.key', '/CN=Test Intermediate', 'mid.csr'));
  run(`openssl x509 -req -in ${join(dir, 'mid.csr')} -CA ${join(dir, 'root.pem')} -CAkey ${join(dir, 'root.key')} -CAcreateserial -days 3650 -out ${join(dir, 'mid.pem')}`);
  run(g('leaf.key'));
  run(req('leaf.key', '/CN=leaf', 'leaf.csr'));
  run(`openssl x509 -req -in ${join(dir, 'leaf.csr')} -CA ${join(dir, 'mid.pem')} -CAkey ${join(dir, 'mid.key')} -CAcreateserial -days 3650 -out ${join(dir, 'leaf.pem')}`);
  run(g('leaf2.key'));
  run(req('leaf2.key', '/CN=leaf2', 'leaf2.csr'));
  run(`openssl x509 -req -in ${join(dir, 'leaf2.csr')} -CA ${join(dir, 'root.pem')} -CAkey ${join(dir, 'root.key')} -CAcreateserial -days 3650 -out ${join(dir, 'leaf2.pem')}`);

  const b64url = (b: Buffer | string) => Buffer.from(b).toString('base64url');
  const pad32 = (b: Buffer) => b.length < 32 ? Buffer.concat([Buffer.alloc(32 - b.length), b]) : b.subarray(b.length - 32);
  const derToRaw = (der: Buffer) => {
    let i = 1;
    if (der[i] & 0x80) i += der[i] & 0x7f;
    i += 1;
    assert.equal(der[i], 0x02, 'r tag');
    const r = der.subarray(i + 2, i + 2 + der[i + 1]);
    i += 2 + der[i + 1];
    assert.equal(der[i], 0x02, 's tag');
    const s = der.subarray(i + 2, i + 2 + der[i + 1]);
    return Buffer.concat([pad32(r), pad32(s)]);
  };

  const leafKey = readFileSync(join(dir, 'leaf.key'), 'utf8');
  const payload = {
    transactionId: '1000000123456789',
    originalTransactionId: '1000000123456789',
    bundleId: 'com.game.Warringstates',
    productId: 'gem_300',
    purchaseDate: 1750000000000,
    quantity: 1,
    type: 'Consumable',
    inAppOwnershipType: 'PURCHASED',
    signedDate: 1750000000000,
    environment: 'Sandbox',
  };
  const build = (p: unknown, chain: string[], key: string) => {
    const header = { alg: 'ES256', typ: 'JWT', x5c: chain };
    const h = b64url(JSON.stringify(header));
    const b = b64url(JSON.stringify(p));
    const der = sign('sha256', Buffer.from(`${h}.${b}`), key);
    return `${h}.${b}.${b64url(derToRaw(der))}`;
  };

  const chain3 = [derB64('leaf.pem'), derB64('mid.pem'), derB64('root.pem')];
  const jws = build(payload, chain3, leafKey);

  let r = verifyJws(jws, 'gem_300', cert('root.pem'));
  assert.deepEqual(r, { productId: 'gem_300', transactionId: '1000000123456789', bundleId: 'com.game.Warringstates' });

  r = verifyJws(jws, 'gem_60', cert('root.pem'));
  assert.equal('error' in r && r.error, 'Product mismatch');

  const sig = jws.split('.')[2];
  const flipped = sig.slice(0, 10) + (sig[10] === 'A' ? 'B' : 'A') + sig.slice(11);
  const tampered = `${jws.split('.')[0]}.${jws.split('.')[1]}.${flipped}`;
  r = verifyJws(tampered, 'gem_300', cert('root.pem'));
  assert.equal('error' in r && r.error, 'JWS signature invalid');

  const wrongBundle = build({ ...payload, bundleId: 'com.evil.app' }, chain3, leafKey);
  r = verifyJws(wrongBundle, 'gem_300', cert('root.pem'));
  assert.equal('error' in r && r.error, 'Apple bundle ID mismatch');

  const qty = build({ ...payload, quantity: 2 }, chain3, leafKey);
  r = verifyJws(qty, 'gem_300', cert('root.pem'));
  assert.equal('error' in r && r.error, 'Invalid Apple quantity');

  const chain2 = [derB64('leaf2.pem'), derB64('root.pem')];
  const jws2 = build(payload, chain2, readFileSync(join(dir, 'leaf2.key'), 'utf8'));
  r = verifyJws(jws2, 'gem_300', cert('root.pem'));
  assert.equal('error' in r, false, '2-cert chain should pass');

  r = verifyJws('no-dots-here', 'gem_300', cert('root.pem'));
  assert.equal('error' in r && r.error, 'Malformed JWS');
  r = verifyJws('not.a.jws', 'gem_300', cert('root.pem'));
  assert.equal('error' in r && r.error, 'Malformed JWS payload');

  r = verifyStoreKit2Jws(jws, 'gem_300');
  assert.equal('error' in r, true, 'forged chain must be rejected by real Apple root');

  console.log('ALL_JWS_TESTS_PASS');
} finally {
  rmSync(dir, { recursive: true, force: true });
}
