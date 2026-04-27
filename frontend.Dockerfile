# Stage 1: Build the React application
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package.json and package-lock.json
COPY guess_game-main/frontend/package*.json ./

# Install dependencies using clean install for predictable builds
RUN npm ci

# Copy the rest of the application
COPY guess_game-main/frontend/ .

# Set environment variable so the build knows the API URL
ENV REACT_APP_BACKEND_URL=/api

# Build the app
RUN npm run build

# Stage 2: Serve the app with NGINX and act as reverse proxy
FROM nginx:alpine

# Copy built assets from builder
COPY --from=builder /app/build /usr/share/nginx/html

# Copy the NGINX configuration from the root folder
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start NGINX
CMD ["nginx", "-g", "daemon off;"]
