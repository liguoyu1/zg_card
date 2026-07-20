// Minimal self-check: gem product mapping + bonus logic (pure, no DB/Apple)
const GEM_BASE_MAP: Record<string, number> = {
  gem_60: 60, gem_300: 300, gem_600: 600, gem_1500: 1500, gem_3000: 3000,
};
function iapGemBonus(base: number): number {
  const map: Record<number, number> = { 60: 0, 300: 50, 600: 150, 1500: 500, 3000: 1500 };
  return map[base] ?? 0;
}

const expected: [string, number, number][] = [
  ['gem_60', 60, 0],
  ['gem_300', 300, 50],
  ['gem_600', 600, 150],
  ['gem_1500', 1500, 500],
  ['gem_3000', 3000, 1500],
];

let ok = true;
for (const [pid, base, bonus] of expected) {
  const m = GEM_BASE_MAP[pid];
  const b = iapGemBonus(m);
  if (m !== base || b !== bonus) {
    console.error(`FAIL: ${pid} -> base=${m} (expected ${base}), bonus=${b} (expected ${bonus})`);
    ok = false;
  } else {
    console.log(`PASS: ${pid} -> ${m}+${b} = ${m + b}`);
  }
}
process.exit(ok ? 0 : 1);
