'use client';
import { useEffect, useState } from 'react';
const api = (u, m = 'GET', b) => fetch(u, { method: m, headers: { 'Content-Type': 'application/json' }, body: b && JSON.stringify(b) }).then(r => r.json());
export default function Home() {
  const [me, setMe] = useState(null), [d, setD] = useState(null), [ideas, setIdeas] = useState([]), [msg, setMsg] = useState('');
  const [f, setF] = useState({ email: 'admin@hack.com', password: 'password123' }), [q, setQ] = useState('');
  const [idea, setIdea] = useState({ title: '', description: '', tags: '' }), [sc, setSc] = useState({ project_id: 1, innovation: 5, technical: 5, impact: 5 }), [tn, setTn] = useState(''), [fb, setFb] = useState(null), [ff, setFf] = useState({ project_id: 1, rating: 5, comment: '' });
  const load = async (query = '') => {
    const u = await api('/api/login'); if (u.error) return setMe(null); setMe(u);
    setD(await api('/api/data')); setIdeas(await api('/api/ideas' + (query ? '?q=' + encodeURIComponent(query) : ''))); setFb(await api('/api/feedback'));
  };
  useEffect(() => { load(); }, []);
  const act = async (fn) => { const r = await fn(); setMsg(r.error || 'Done'); load(q); };
  if (!me) return <main><div className="card"><h2>Hackathon Management System</h2>
    <input placeholder="email" value={f.email} onChange={e => setF({ ...f, email: e.target.value })} />
    <input type="password" value={f.password} onChange={e => setF({ ...f, password: e.target.value })} />
    <button onClick={async () => { const r = await api('/api/login', 'POST', f); r.error ? setMsg(r.error) : load(); }}>Login</button>
    <p>{msg}</p><small>Demo: admin@hack.com / priya@hack.com (judge) / aarav@mail.com (participant) / mentor@hack.com (mentor). Password: password123</small></div></main>;
  return <main>
    <div className="card row" style={{ justifyContent: 'space-between' }}><b>Logged in: {me.email} ({me.role})</b>
      <button onClick={async () => { await api('/api/login', 'DELETE'); setMe(null); }}>Logout</button></div>
    {msg && <div className="card">{msg}</div>}
    {d && <><div className="row">{[['Participants', d.stats.participants], ['Teams', d.stats.teams], ['Projects', d.stats.projects], ['Funding', d.stats.funding]].map(([k, v]) => <div className="card" key={k}><small>{k}</small><div className="big">{v}</div></div>)}</div>
      <div className="card"><b>Leaderboard</b><table><tbody>{d.leaderboard.map(r => <tr key={r.project_id}><td>#{r.rnk}</td><td>{r.title}</td><td>{r.team_name}</td><td>{r.avg_total}</td></tr>)}</tbody></table></div>
      <div className="card"><b>Teams</b><table><tbody>{d.teams.map(t => <tr key={t.team_id}><td>{t.team_name}</td><td>{t.members}</td></tr>)}</tbody></table></div>
      {me.role === 'judge' && <div className="card"><b>Submit score (judge only)</b><br />
        {['project_id', 'innovation', 'technical', 'impact'].map(k => <input key={k} type="number" placeholder={k} value={sc[k]} onChange={e => setSc({ ...sc, [k]: +e.target.value })} style={{ width: 90 }} />)}
        <button onClick={() => act(() => api('/api/score', 'POST', sc))}>Save</button></div>}
      {me.role === 'participant' && <div className="card"><b>Register a team (participant only)</b><br /><input placeholder="team name" value={tn} onChange={e => setTn(e.target.value)} />
        <button onClick={() => act(() => api('/api/teams', 'POST', { team_name: tn }))}>Register</button></div>}
      {fb && fb.summary && <div className="card"><b>Mentor feedback</b>
        <table><tbody>{fb.summary.map(s => <tr key={s.project_id}><td>{s.title}</td><td>{s.team_name}</td><td>{s.reviews} reviews</td><td>avg {s.avg_rating ?? '-'}</td></tr>)}</tbody></table>
        <small>Latest comments</small>
        {fb.recent.map(r => <div key={r.feedback_id}><b>{r.title}</b> - {r.mentor}: {r.rating}/5 {r.comment}</div>)}</div>}
      {me.role === 'mentor' && <div className="card"><b>Give feedback (mentor only)</b><br />
        <input type="number" placeholder="project_id" value={ff.project_id} onChange={e => setFf({ ...ff, project_id: +e.target.value })} style={{ width: 90 }} />
        <input type="number" min="1" max="5" placeholder="rating 1-5" value={ff.rating} onChange={e => setFf({ ...ff, rating: +e.target.value })} style={{ width: 90 }} />
        <input placeholder="comment" value={ff.comment} onChange={e => setFf({ ...ff, comment: e.target.value })} />
        <button onClick={() => act(() => api('/api/feedback', 'POST', ff))}>Submit</button></div>}
      {me.role === 'admin' && <div className="card"><b>Audit log (admin only, filled by trigger)</b><table><tbody>{d.audit.map(a => <tr key={a.log_id}><td>{a.action}</td><td>{a.details}</td></tr>)}</tbody></table></div>}</>}
    <div className="card"><b>Project ideas (MongoDB)</b><br />
      <input placeholder="semantic search e.g. farming AI" value={q} onChange={e => setQ(e.target.value)} /><button onClick={() => load(q)}>Find similar</button>
      {ideas.map(i => <div key={i._id} style={{ borderTop: '1px solid #eee', padding: '8px 0' }}><b>{i.title}</b> {i.score !== undefined && <small>similarity {i.score}</small>}<br />{i.description}<br />{(i.tags || []).map(t => <span className="tag" key={t}>{t}</span>)}
        {(me.role === 'admin' || i.author === me.email) && <> <button onClick={() => { const t = prompt('New title', i.title); if (t) act(() => api('/api/ideas/' + i._id, 'PUT', { title: t, description: i.description })); }}>Edit</button>
          <button onClick={() => act(() => api('/api/ideas/' + i._id, 'DELETE'))}>Delete</button></>}</div>)}
      <hr /><input placeholder="title" value={idea.title} onChange={e => setIdea({ ...idea, title: e.target.value })} /><input placeholder="description" value={idea.description} onChange={e => setIdea({ ...idea, description: e.target.value })} />
      <input placeholder="tags,comma" value={idea.tags} onChange={e => setIdea({ ...idea, tags: e.target.value })} /><button onClick={() => act(() => api('/api/ideas', 'POST', idea))}>Add idea</button></div>
  </main>;
}
