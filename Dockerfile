# Multi-stage build for the entire application
# FROM openjdk:11 as builder

# WORKDIR /build
# COPY HelloWorld.java .
# RUN javac HelloWorld.java

# # Final stage
# FROM openjdk:11-jre-slim

# # Install nginx
# RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

# WORKDIR /app

# # Copy compiled Java application
# COPY --from=builder /build/HelloWorld.class .
# COPY HelloWorld.java .

# # Copy HTML calculator
# COPY calculator.html /var/www/html/index.html

# # Copy nginx config
# COPY nginx.conf /etc/nginx/nginx.conf

# EXPOSE 80 8080

# # Start nginx and Java app
# CMD nginx && java HelloWorld


##--- Stage 1: Build Stage ---
# Use a specific and well-supported JDK image from Eclipse Temurin
FROM maven:3.8.5-eclipse-temurin-11 AS builder

# Set the working directory
WORKDIR /app

# Copy the pom.xml file to download dependencies first (caching layer)
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy the rest of the source code
COPY src ./src

# Build the project, creating a single runnable JAR file
RUN mvn package


# --- Stage 2: Final Runtime Stage ---
# Use a lightweight JRE image for the final, smaller image
FROM eclipse-temurin:11-jre-focal

# Set the working directory
WORKDIR /app

# Copy the runnable JAR from the builder stage
COPY --from=builder /app/target/calculator-app-1.0.jar .

# Expose the port the server is listening on
EXPOSE 8080

# Command to run the web server
CMD ["java", "-jar", "calculator-app-1.0.jar"]
