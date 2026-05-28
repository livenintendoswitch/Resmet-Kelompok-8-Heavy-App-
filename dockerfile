# FROM node:18-alpine
# WORKDIR /app
# COPY package*.json ./
# RUN npm install --legacy-peer-deps
# COPY . .
# ENV DATABASE_URL="sqlite:///app/database.sqlite"
# RUN node ./bin/sync-db.js
# RUN npm run build
# EXPOSE 3000
# CMD ["npm", "start"]

FROM node:18-alpine

RUN apk add --no-cache sqlite

WORKDIR /app
COPY package*.json ./
RUN npm install --legacy-peer-deps
COPY . .

ENV DATABASE_URL="sqlite:///app/database.sqlite"

RUN node ./bin/sync-db.js

RUN sqlite3 /app/database.sqlite ".tables"

RUN npm run build

EXPOSE 3000
CMD ["npm", "start"]