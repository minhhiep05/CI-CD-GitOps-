FROM node:22-alpine
WORKDIR /app
COPY package.json .
COPY src ./src
RUN rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx
EXPOSE 3000
CMD ["node", "src/index.js"]
