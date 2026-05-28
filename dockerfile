FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --legacy-peer-deps
COPY . .
RUN node ./bin/sync-db.js
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]

