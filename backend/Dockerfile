# Backend Dockerfile
FROM node:20-alpine AS base

WORKDIR /app

COPY package*.json .

RUN npm install --only=production -ignore-scripts

FROM node:20-alpine AS run 

WORKDIR /app

COPY --from=base /app/node_modules/ ./node_modules

COPY . .

RUN addgroup -S appgroup && adduser -S appuser -G appgroup && chown -R appuser:appgroup /app

USER appuser

ENV NODE_ENV=production

EXPOSE 4000

CMD [ "npm", "start" ]