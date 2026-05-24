FROM node:22-alpine

WORKDIR /gateway

COPY package.json ./
COPY server.mjs ./

EXPOSE 8088

CMD ["node", "server.mjs"]
