const Database = require('better-sqlite3');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

const db = new Database('yumyum.db');
const hashedPassword = bcrypt.hashSync('123456', 10);

db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    profileImageUrl TEXT
  );

  CREATE TABLE IF NOT EXISTS recipes (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    ingredients TEXT,
    imageUrl TEXT,
    userId TEXT,
    type TEXT,
    price REAL,
    createdAt TEXT,
    allergens TEXT,
    FOREIGN KEY(userId) REFERENCES users(id)
  );

  CREATE TABLE IF NOT EXISTS ratings (
    id TEXT PRIMARY KEY,
    targetId TEXT NOT NULL,
    targetType TEXT NOT NULL,
    authorId TEXT NOT NULL,
    value INTEGER NOT NULL,
    comment TEXT,
    FOREIGN KEY(authorId) REFERENCES users(id)
  );
`);

function seed() {
  const users = [
    { id: '1', name: 'Usuario de Prueba', email: 'test@example.com' },
    { id: '2', name: 'Ana', email: 'ana@ejemplo.com' },
    { id: '3', name: 'Carlos', email: 'carlos@ejemplo.com' },
    { id: '4', name: 'María', email: 'maria@ejemplo.com' },
  ];

  for (const u of users) {
    try {
      db.prepare('INSERT INTO users (id, name, email, password) VALUES (?, ?, ?, ?)').run(u.id, u.name, u.email, hashedPassword);
    } catch (e) {}
  }

  const recipes = [
    {
      id: '101',
      title: 'Tarta de Manzana Casera',
      description: 'He hecho demasiada tarta de manzana. Intercambio por algún postre salado o vendo mi porción extra.',
      imageUrl: 'https://images.unsplash.com/photo-1568571780765-9276ac8b75a2?w=500',
      userId: '2',
      type: 'exchange',
      price: null,
      createdAt: new Date().toISOString(),
      allergens: JSON.stringify(['Gluten'])
    },
    {
      id: '102',
      title: 'Tupper de Lentejas',
      description: 'Lentejas tradicionales con chorizo. Ración grande. Vendo porque cociné para toda la semana.',
      imageUrl: 'https://images.unsplash.com/photo-1548811218-12c8b87ee077?w=500',
      userId: '3',
      type: 'sell',
      price: 4.50,
      createdAt: new Date().toISOString(),
      allergens: JSON.stringify([])
    },
    {
      id: '103',
      title: 'Pan de Masa Madre',
      description: 'Pan artesano recién horneado. Cambio por huevos camperos.',
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500',
      userId: '4',
      type: 'exchange',
      price: null,
      createdAt: new Date().toISOString(),
      allergens: JSON.stringify(['Gluten'])
    }
  ];

  for (const r of recipes) {
    try {
      db.prepare('INSERT INTO recipes (id, title, description, imageUrl, userId, type, price, createdAt, allergens) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)').run(
        r.id, r.title, r.description, r.imageUrl, r.userId, r.type, r.price, r.createdAt, r.allergens
      );
    } catch (e) {
      console.log(`Recipe ${r.id} already exists`);
    }
  }

  console.log('Database seeded successfully');
}

seed();
