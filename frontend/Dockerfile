# Frontend Dockerfile
FROM node:20-alpine AS build

WORKDIR /app 

COPY package*.json . 

RUN npm install --only-production -ignore-scripts

COPY . .

ARG VITE_API_BASE_URL

ENV VITE_API_BASE_URL=$VITE_API_BASE_URL

RUN npm run build

FROM  nginxinc/nginx-unprivileged:1.27-alpine AS run

WORKDIR /usr/share/nginx/html

COPY --from=build app/dist . 

USER nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]