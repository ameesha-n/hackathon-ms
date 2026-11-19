// Seeds demo users (MySQL) and ideas with embeddings (MongoDB). Password for all users: password123
import mysql from 'mysql2/promise'; import bcrypt from 'bcryptjs'; import { MongoClient } from 'mongodb';
function embed(t){const v=new Array(64).fill(0);for(const w of t.toLowerCase().match(/[a-z]{3,}/g)||[]){let h=0;for(const c of w)h=(h*31+c.charCodeAt(0))%64;v[h]++;}const n=Math.hypot(...v)||1;return v.map(x=>x/n);}
const db = await mysql.createConnection(process.env.MYSQL_URL);
const hash = await bcrypt.hash('password123', 10);
for (const [e, r, p, j] of [['admin@hack.com',1,null,null],['priya@hack.com',2,null,3],['aarav@mail.com',3,1,null]])
  await db.query('INSERT IGNORE INTO app_user (email,password_hash,role_id,participant_id,judge_id) VALUES (?,?,?,?,?)', [e, hash, r, p, j]);
await db.query("INSERT IGNORE INTO app_user (email,password_hash,role_id,mentor_id) SELECT ?, ?, role_id, 1 FROM role WHERE role_name='mentor'", ['mentor@hack.com', hash]);
const m = await new MongoClient(process.env.MONGO_URL).connect(); const c = m.db('hackathon_nosql').collection('ideas');
await c.deleteMany({});
await c.insertMany([
 ['Crop disease detector','Use computer vision on leaf photos to detect crop disease for farmers',['ai','agri']],
 ['Hospital records on blockchain','Secure sharing of patient medical records between hospitals',['health','blockchain']],
 ['Smart energy grid','Balance solar and battery power for neighbourhood energy savings',['energy','iot']],
 ['Women safety route planner','Suggest safe walking routes using crowd reports and street lighting data',['social','maps']],
].map(([title,description,tags]) => ({ title, description, tags, author:'seed', embedding: embed(title+' '+description), created_at:new Date() })));
console.log('Seeded'); await db.end(); await m.close();
