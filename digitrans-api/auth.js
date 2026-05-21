const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'digitrans_secure_secret_key_2026';

module.exports = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Accès non autorisé : Jeton manquant' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Accès refusé : Jeton invalide ou expiré' });
    }
    req.user = user;
    next();
  });
};
