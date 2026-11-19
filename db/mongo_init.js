// mongosh db/mongo_init.js
use hackathon_nosql;
db.createCollection('ideas', { validator: { $jsonSchema: {
  bsonType: 'object', required: ['title','description','author','embedding'],
  properties: { title:{bsonType:'string'}, description:{bsonType:'string'},
    tags:{bsonType:'array', items:{bsonType:'string'}}, author:{bsonType:'string'},
    embedding:{bsonType:'array'} } } } });
db.ideas.createIndex({ tags: 1 });
db.ideas.createIndex({ title: 'text', description: 'text' });
