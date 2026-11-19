// Hashed bag-of-words embedding (64-dim). Replace with a real model / Atlas Vector Search in production.
export function embed(t) {
  const v = new Array(64).fill(0);
  for (const w of t.toLowerCase().match(/[a-z]{3,}/g) || []) { let h = 0; for (const c of w) h = (h * 31 + c.charCodeAt(0)) % 64; v[h]++; }
  const n = Math.hypot(...v) || 1; return v.map(x => x / n);
}
export const cosine = (a, b) => a.reduce((s, x, i) => s + x * b[i], 0);
