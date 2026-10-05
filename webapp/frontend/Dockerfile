# Baut die Angular-Anwendung und liefert sie über nginx aus,
# das gleichzeitig /api an das Backend weiterreicht.
FROM node:24-bookworm AS build
WORKDIR /build
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /build/dist/frontend/browser /usr/share/nginx/html
EXPOSE 80
