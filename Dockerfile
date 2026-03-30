# Multi-stage build for the entire application
FROM eclipse-temurin:11-jdk as builder

WORKDIR /build
COPY HelloWorld.java .
RUN javac HelloWorld.java

# Final stage
FROM eclipse-temurin:11-jre

# Install nginx
RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy compiled Java application
COPY --from=builder /build/HelloWorld.class .
COPY HelloWorld.java .

# Copy HTML calculator
COPY calculator.html /var/www/html/index.html

# Copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

# Start nginx in background
CMD ["sh", "-c", "nginx -g 'daemon off;'"]
