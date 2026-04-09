const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const Database = require('better-sqlite3');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

const app = express();
const port = 3000;
const secret = 'yumyum-super-secret';

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// DB Setup
const db = new Database('yumyum.db');
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
    targetType TEXT NOT NULL, -- 'recipe' or 'user'
    authorId TEXT NOT NULL,
    value INTEGER NOT NULL,
    comment TEXT,
    FOREIGN KEY(authorId) REFERENCES users(id)
  );
`);

// Multer Setup
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadPath = path.join(__dirname, 'uploads');
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname))
});
const upload = multer({ storage });

// Endpoints
app.post('/auth/register', async (req, res) => {
  const { name, email, password } = req.body;
  const hashedPassword = await bcrypt.hash(password, 10);
  const id = uuidv4();
  try {
    const stmt = db.prepare('INSERT INTO users (id, name, email, password) VALUES (?, ?, ?, ?)');
    stmt.run(id, name, email, hashedPassword);
    const token = jwt.sign({ id }, secret);
    res.json({ user: { id, name, email }, token });
  } catch (e) {
    console.error(e);
    res.status(400).json({ error: 'Email already exists' });
  }
});

app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body;
  const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email);
  if (user && await bcrypt.compare(password, user.password)) {
    const token = jwt.sign({ id: user.id }, secret);
    res.json({ user: { id: user.id, name: user.name, email: user.email }, token });
  } else {
    res.status(401).json({ error: 'Invalid credentials' });
  }
});

app.get('/recipes', (req, res) => {
  const recipes = db.prepare(`
    SELECT r.*, u.name as ownerName, u.email as ownerEmail, u.profileImageUrl as ownerProfileImage 
    FROM recipes r 
    JOIN users u ON r.userId = u.id
    ORDER BY r.createdAt DESC
  `).all();
  
  // Transform to match Flutter model if needed
  const transformed = recipes.map(r => ({
    ...r,
    allergens: JSON.parse(r.allergens || '[]'),
    owner: {
      id: r.userId,
      name: r.ownerName,
      email: r.ownerEmail,
      profileImageUrl: r.ownerProfileImage
    }
  }));
  
  res.json(transformed);
});

app.post('/recipes', upload.any(), (req, res) => {
  const file = req.files ? req.files[0] : null;
  console.log('=== DATA RECEIVED ===');
  console.log('Headers:', req.headers['content-type']);
  console.log('Files Count:', req.files ? req.files.length : 0);
  if (req.files && req.files.length > 0) {
    console.log('First File Name:', req.files[0].fieldname);
  }
  console.log('Body Content:', JSON.stringify(req.body, null, 2));

  const { title, description, ingredients, userId, type, price, allergens, imageUrl: bodyImageUrl } = req.body;
  
  const getVal = (v) => (v === 'null' || v === 'undefined' || v === '') ? null : v;
  
  const finalTitle = getVal(title) || 'Sin título';
  const finalDesc = getVal(description) || '';
  const finalUserId = getVal(userId);
  const finalType = getVal(type) || 'exchange';
  const finalPrice = (price && price !== 'null') ? parseFloat(price) : null;
  const finalAllergens = getVal(allergens) || '[]';
  
  const imageUrl = file ? `/uploads/${file.filename}` : (getVal(bodyImageUrl) || null);
  
  console.log('Resolved Image URL:', imageUrl);
  console.log('Resolved User ID:', finalUserId);

  const id = uuidv4();
  const createdAt = new Date().toISOString();
  
  try {
    const stmt = db.prepare('INSERT INTO recipes (id, title, description, ingredients, imageUrl, userId, type, price, createdAt, allergens) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
    stmt.run(id, finalTitle, finalDesc, getVal(ingredients) || '', imageUrl, finalUserId, finalType, finalPrice, createdAt, finalAllergens);
    
    res.json({ 
      id, 
      title: finalTitle, 
      description: finalDesc, 
      ingredients: getVal(ingredients) || '', 
      imageUrl, 
      userId: finalUserId, 
      type: finalType, 
      price: finalPrice, 
      createdAt, 
      allergens: JSON.parse(finalAllergens)
    });
    console.log('Recipe saved successfully:', id);
  } catch (err) {
    console.error('DATABASE ERROR:', err);
    res.status(500).json({ error: 'Failed to save recipe', details: err.message });
  }
});

app.post('/ratings', (req, res) => {
  const { targetId, targetType, authorId, value, comment } = req.body;
  const id = uuidv4();
  const stmt = db.prepare('INSERT INTO ratings (id, targetId, targetType, authorId, value, comment) VALUES (?, ?, ?, ?, ?, ?)');
  stmt.run(id, targetId, targetType, authorId, value, comment);
  res.json({ id, targetId, targetType, authorId, value, comment });
});

app.get('/ratings/:targetId', (req, res) => {
  const ratings = db.prepare('SELECT * FROM ratings WHERE targetId = ?').all(req.params.targetId);
  res.json(ratings);
});

// AI Gemini Integration
const { GoogleGenerativeAI } = require("@google/generative-ai");
const genAI = new GoogleGenerativeAI("AIzaSyA2obspEmlZ3DMk3Qb8SZP8ozuanvwvdcc");

// Configuramos el modelo con una instrucción de sistema simple
const aiModel = genAI.getGenerativeModel({ 
  model: "gemini-1.5-flash",
});

const SYSTEM_PROMPT = "Eres el asistente culinario de YumYum, una app de intercambio de comida casera. Tu objetivo es ayudar a los usuarios con recetas, consejos de cocina, aprovechamiento de ingredientes y fomento de la comunidad. Sé amable, cercano y profesional. ";

app.post('/chat/ai', async (req, res) => {
  const { message } = req.body;
  console.log('--- AI Chat Request (Gemini) ---');
  console.log('Message:', message);
  
  try {
    if (!genAI.apiKey || genAI.apiKey === "YOUR_API_KEY") {
      return res.json({ reply: "¡Hola! Por ahora soy un simulador porque no hay API Key configurada. Pero me has preguntado: " + message });
    }

    // Usamos un bloque try-catch interno para probar el modelo flash y si falla probar pro
    try {
      // Probamos con el nombre completo del modelo
      const result = await aiModel.generateContent(SYSTEM_PROMPT + "\n\nUsuario: " + message);
      const response = await result.response;
      const reply = response.text();
      res.json({ reply });
    } catch (innerErr) {
      console.error('INNER GEMINI ERROR (Flash):', innerErr.message || innerErr);
      
      try {
        // Segundo intento con gemini-1.5-pro
        console.log('--- Falling back to Gemini 1.5 Pro ---');
        const proModel = genAI.getGenerativeModel({ model: "gemini-1.5-pro" });
        const result = await proModel.generateContent(SYSTEM_PROMPT + "\n\nUsuario: " + message);
        const response = await result.response;
        res.json({ reply: response.text() });
      } catch (err2) {
        console.error('LAST AI ERROR:', err2.message || err2);
        
        try {
          // Tercer intento con gemini-pro (1.0)
          console.log('--- Falling back to Gemini Pro (1.0) ---');
          const oldModel = genAI.getGenerativeModel({ model: "gemini-pro" });
          const result = await oldModel.generateContent(SYSTEM_PROMPT + "\n\nUsuario: " + message);
          const response = await result.response;
          res.json({ reply: response.text() });
        } catch (err3) {
          console.error('CRITICAL AI ERROR:', err3.message || err3);
          
          // RESPUESTA DE EMERGENCIA (Local) si la API de Google falla por completo
          let localReply = "Lo siento, mi conexión con los servidores de Google IA está teniendo problemas técnicos. ";
          
          const msg = message.toLowerCase();
          if (msg.includes("gamba") || msg.includes("aguacate") || msg.includes("patata")) {
            localReply += "¡Pero tengo una respuesta guardada para ti! Con esos ingredientes puedes hacer unas deliciosas **Gambas al Ajillo con Patatas Panaderas**. Opcionalmente puedes añadir un poco de aguacate al lado para darle frescura.";
          } else if (msg.includes("hola") || msg.includes("ayuda")) {
            localReply += "¡Hola! Soy tu asistente de YumYum. Puedo ayudarte a buscar recetas o consejos de cocina. Inténtalo de nuevo en unos minutos o pregúntame algo sobre ingredientes específicos.";
          } else {
            localReply += "Parece que hay un problema con la configuración de la clave de API en este momento. Por favor, revisa la consola del servidor.";
          }
          
          res.json({ reply: localReply });
        }
      }
    }
  } catch (err) {
    console.error('FINAL SERVER ERROR:', err);
    res.status(500).json({ reply: "Error interno del servidor. Inténtalo en un momento." });
  }
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Server running at http://0.0.0.0:${port}`);
});
