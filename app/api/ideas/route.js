import { ideas } from '@/lib/mongo';
import { embed, cosine } from '@/lib/embed';
import { guard } from '@/lib/auth';
export async function GET(req) {                       // READ + vector similarity search
  const [, err] = await guard(); if (err) return err;
  const q = new URL(req.url).searchParams.get('q');
  const all = await (await ideas()).find().toArray();
  if (!q) return Response.json(all.map(({ embedding, ...r }) => r));
  const e = embed(q);
  return Response.json(all.map(({ embedding, ...r }) => ({ ...r, score: +cosine(e, embedding).toFixed(3) })).sort((a, b) => b.score - a.score));
}
export async function POST(req) {                      // CREATE
  const [u, err] = await guard(); if (err) return err;
  const { title, description, tags } = await req.json();
  await (await ideas()).insertOne({ title, description, tags: (tags || '').split(',').map(s => s.trim()).filter(Boolean), author: u.email, embedding: embed(title + ' ' + description), created_at: new Date() });
  return Response.json({ ok: true });
}
