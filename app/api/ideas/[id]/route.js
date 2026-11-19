import { ObjectId } from 'mongodb';
import { ideas } from '@/lib/mongo';
import { embed } from '@/lib/embed';
import { guard } from '@/lib/auth';
async function owned(id, u) {
  const c = await ideas(); const doc = await c.findOne({ _id: new ObjectId(id) });
  return doc && (u.role === 'admin' || doc.author === u.email) ? c : null;
}
export async function PUT(req, { params }) {           // UPDATE (owner or admin)
  const [u, err] = await guard(); if (err) return err;
  const { id } = await params;
  const c = await owned(id, u); if (!c) return Response.json({ error: 'Forbidden' }, { status: 403 });
  const { title, description } = await req.json();
  await c.updateOne({ _id: new ObjectId(id) }, { $set: { title, description, embedding: embed(title + ' ' + description) } });
  return Response.json({ ok: true });
}
export async function DELETE(req, { params }) {        // DELETE (owner or admin)
  const [u, err] = await guard(); if (err) return err;
  const { id } = await params;
  const c = await owned(id, u); if (!c) return Response.json({ error: 'Forbidden' }, { status: 403 });
  await c.deleteOne({ _id: new ObjectId(id) });
  return Response.json({ ok: true });
}
