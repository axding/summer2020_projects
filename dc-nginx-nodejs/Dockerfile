FROM node:10-alpine

WORKDIR /usr/src/service

COPY package*.json ./.

RUN npm install

COPY app.js ./.

EXPOSE 8080

CMD [ "node", "app.js" ]
