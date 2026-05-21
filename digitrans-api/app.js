require('dotenv').config();
const express = require('express');
const jwt = require('jsonwebtoken');
const swaggerUi = require('swagger-ui-express');
const verifyToken = require('./auth');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'digitrans_secure_secret_key_2026';

// Spécification OpenAPI / Swagger conforme aux attentes de l'épreuve
const swaggerDocument = {
  openapi: "3.0.0",
  info: {
    title: "DIGITRANS-CM - Supply Chain Management API",
    version: "1.0.0",
    description: "Documentation des APIs pour l'optimisation du système d'information de DIGITRANS-CM"
  },
  paths: {
    "/api/login": {
      post: {
        summary: "Authentification de l'utilisateur et génération du token JWT",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  username: { type: "string" },
                  password: { type: "string" }
                }
              }
            }
          }
        },
        responses: {
          "200": { description: "Authentification réussie, token retourné" },
          "400": { description: "Identifiants invalides" }
        }
      }
    },
    "/api/data": {
      get: {
        summary: "Récupération des flux de marchandises (Sécurisé par JWT)",
        security: [{ bearerAuth: [] }],
        responses: {
          "200": { description: "Succès - Retourne les données de la supply chain" },
          "401": { description: "Jeton manquant" },
          "403": { description: "Jeton invalide" }
        }
      }
    }
  },
  components: {
    securitySchemes: {
      bearerAuth: {
        type: "http",
        scheme: "bearer",
        bearerFormat: "JWT"
      }
    }
  }
};

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  if (username === 'camtech' && password === 'digitrans2026') {
    const token = jwt.sign({ username, role: 'admin' }, JWT_SECRET, { expiresIn: '2h' });
    return res.json({ token });
  }
  res.status(400).json({ error: 'Identifiants incorrects' });
});

app.get('/api/data', verifyToken, (req, res) => {
  res.json({
    status: "Succès",
    message: "Accès autorisé aux données de gestion de flotte DIGITRANS-CM",
    client: "CAMTECH SOLUTIONS S.A.",
    flux: [
      { id: 1, marchandise: "Composants Électroniques", entrepot: "Douala Port", statut: "En transit" },
      { id: 2, marchandise: "Matériel Informatique", entrepot: "Yaoundé Centre", statut: "Stocké" }
    ],
    user: req.user
  });
});

app.listen(PORT, () => {
  console.log(`==================================================`);
  console.log(`🚀 Serveur DIGITRANS démarré sur le port : ${PORT}`);
  console.log(`📖 Documentation Swagger disponible sur http://localhost:${PORT}/api-docs`);
  console.log(`==================================================`);
});
