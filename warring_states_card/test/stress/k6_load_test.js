// k6 load test — 战国卡牌 API
// Usage: k6 run test/stress/k6_load_test.js

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const BASE_URL = __ENV.BASE_URL || 'https://warring-states-card.up.railway.app';

const errorRate = new Rate('errors');
const matchTime = new Trend('match_check_time');

export const options = {
  stages: [
    { target: 50, duration: '30s' },   // 0→50并发 30s爬升
    { target: 200, duration: '30s' },  // 50→200
    { target: 500, duration: '60s' },  // 200→500 稳态
    { target: 1000, duration: '60s' }, // 500→1000 压力峰值
    { target: 0, duration: '30s' },    // 回落
  ],
  thresholds: {
    http_req_duration: ['p(95)<3000'], // 95%请求<3s
    errors: ['rate<0.05'],             // 错误率<5%
  },
};

export default function () {
  group('Health Check', () => {
    const res = http.get(`${BASE_URL}/api/health`);
    check(res, { 'health ok': (r) => r.status === 200 });
    errorRate.add(res.status !== 200);
  });

  group('Guest Login', () => {
    const payload = JSON.stringify({ name: `stress_${Math.floor(Math.random() * 100000)}` });
    const res = http.post(`${BASE_URL}/api/auth/guest`, payload, {
      headers: { 'Content-Type': 'application/json' },
    });
    const ok = check(res, {
      'login success': (r) => r.status === 200,
      'has token': (r) => r.json('token') !== undefined,
    });
    errorRate.add(!ok);

    if (ok) {
      const token = res.json('token');
      const playerId = res.json('player.id');

      group('Player Profile', () => {
        const pr = http.get(`${BASE_URL}/api/player/${playerId}`, {
          headers: { 'Authorization': `Bearer ${token}` },
        });
        check(pr, { 'profile ok': (r) => r.status === 200 });
        errorRate.add(pr.status !== 200);
      });

      group('Match Queue', () => {
        // join
        const joinPayload = JSON.stringify({
          odID: playerId,
          odName: `stress_${Math.floor(Math.random() * 10000)}`,
          odHeroId: 'H_B001',
          rating: 1000 + Math.floor(Math.random() * 500),
        });
        const jr = http.post(`${BASE_URL}/api/match/join`, joinPayload, {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`,
          },
        });
        check(jr, { 'join ok': (r) => r.status === 200 });
        errorRate.add(jr.status !== 200);

        // check match
        const checkPayload = JSON.stringify({
          odID: playerId,
          odHeroId: 'H_B001',
          rating: 1000 + Math.floor(Math.random() * 500),
        });
        const mr = http.post(`${BASE_URL}/api/match/check`, checkPayload, {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`,
          },
        });
        matchTime.add(mr.timings.duration);
        check(mr, { 'match check ok': (r) => r.status === 200 });
        errorRate.add(mr.status !== 200);
      });

      group('Leaderboard', () => {
        const lr = http.get(`${BASE_URL}/api/leaderboard?limit=50`);
        check(lr, { 'leaderboard ok': (r) => r.status === 200 });
        errorRate.add(lr.status !== 200);
      });

      group('Rank', () => {
        const rr = http.get(`${BASE_URL}/api/rank/${playerId}`);
        check(rr, { 'rank ok': (r) => r.status === 200 });
        errorRate.add(rr.status !== 200);
      });
    }
  });

  sleep(1);
}
