# Multi-stage build for the entire application
FROM openjdk:11 as builder

WORKDIR /build
COPY HelloWorld.java .
RUN javac HelloWorld.java

# Final stage
FROM openjdk:11-jre-slim

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

EXPOSE 80 8080

# Start nginx and Java app
CMD nginx && java HelloWorld
