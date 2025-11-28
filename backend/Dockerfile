# I'm using Amazon Corretto 8(comptabile with Java 8) as the base image because its optimized and maintained by AWS.
# In this multi-stage Dockerfile, I'm using alpine for lightweight and secure image.

# Build stage
FROM maven:3.9.11-amazoncorretto-8-alpine AS builder

WORKDIR /app

# Copy pom.xml first for better layer caching
COPY pom.xml .

# Download dependencies (cached if pom.xml hasn't changed)
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application, skipping tests here but we can run them in Ci/CD separately if needed.
RUN mvn clean package -DskipTests -B

# Stage 2: Runtime stage
FROM amazoncorretto:8-alpine

# Adding labels for better container management
LABEL maintainer="abbas@tekmetric.com" \
      application="interview" \
      version="1.0.0"

# Install curl for health checks (minimal footprint)
RUN apk add --no-cache curl

# Create non-root user for security
RUN addgroup -S spring && adduser -S spring -G spring

# Set working directory
WORKDIR /app

# Copy the built artifact from builder stage
COPY --from=builder /app/target/interview-1.0-SNAPSHOT.jar app.jar

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Change ownership to non-root user
RUN chown -R spring:spring /app

# Switch to non-root user
USER spring:spring

# Expose application port
EXPOSE 8080

# default values for JVM tuning parameters
# can be overridden via ConfigMap or AWS Secrets Manager
ENV JVM_MAX_RAM_PERCENTAGE=75.0 \
    JVM_MAX_GC_PAUSE_MS=200 \
    JAVA_OPTS=""

# Runs the application using the entrypoint script
# The entrypoint script handles JVM options with proper environment variable expansion
ENTRYPOINT ["/entrypoint.sh"]