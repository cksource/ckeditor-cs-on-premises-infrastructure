FROM node:14-alpine

WORKDIR '/app'
COPY package.json .
RUN npm install
COPY . .

WORKDIR '/app/editor'
RUN npm install 
RUN npm run build 

WORKDIR '/app'
CMD ["npm","start"]