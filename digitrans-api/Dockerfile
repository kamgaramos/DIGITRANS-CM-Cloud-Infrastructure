# 1. Image de base légère
FROM node:18-alpine

# 2. Répertoire de travail dans le conteneur
WORKDIR /usr/src/app

# 3. Copie des fichiers de dépendances
COPY package*.json ./

# 4. Installation propre des modules (sans scripts bloquants)
RUN npm install --ignore-scripts

# 5. Copie du reste du code de l'API
COPY . .

# 6. Exposition du port applicatif
EXPOSE 3000

# 7. Commande de démarrage
CMD [ "node", "app.js" ]
