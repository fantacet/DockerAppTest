FROM node:lts-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# This image is used only to copy dist to a shared volume.
# The CMD copies the dist to the mounted volume path.
FROM node:lts-alpine AS dist
WORKDIR /app
COPY --from=build /app/dist ./dist
CMD ["sh", "-c", "cp -r /app/dist/. /dist && echo 'Frontend dist copied.'"]
