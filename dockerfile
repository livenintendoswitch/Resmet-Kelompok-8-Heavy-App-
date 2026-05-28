FROM node:18-alpine
workdir /app
COPY package.json ./
RUN npm install
COPY . .
env DATABASE_URL=sqlite://memory
RUN npm run build
EXPOSE 3000
cmd ["npm", "start"]
