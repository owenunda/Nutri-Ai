# Etapa 1: Construcción e instalación de dependencias de producción
FROM node:20-alpine AS builder

WORKDIR /usr/src/app

COPY package*.json ./

# Instala solo las dependencias de producción
RUN npm ci --omit=dev

# Etapa 2: Imagen final para ejecución en producción
FROM node:20-alpine AS runner

WORKDIR /usr/src/app

# Copia dependencias y el código fuente
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY package*.json ./
COPY src ./src

# Variables de entorno por defecto para producción
ENV NODE_ENV=production
ENV PORT=3000

# Expone el puerto de la aplicación
EXPOSE 3000

# Comando para iniciar la aplicación
CMD ["node", "src/server.js"]
