import { MongoClient } from 'mongodb';
const p = globalThis._mongo || (globalThis._mongo = new MongoClient(process.env.MONGO_URL).connect());
export const ideas = async () => (await p).db('hackathon_nosql').collection('ideas');
