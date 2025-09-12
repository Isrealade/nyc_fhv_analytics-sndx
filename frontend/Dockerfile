# Frontend Dockerfile
FROM node:20-alpine AS build

WORKDIR /app 

COPY package*.json . 

RUN npm install --only-production -ignore-scripts

COPY . .

RUN npm run build

FROM  nginx:1.27-alpine AS run

COPY default.conf /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/nginx.conf

WORKDIR /usr/share/nginx/html

COPY --from=build app/dist . 

USER nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]