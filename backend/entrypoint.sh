#!/bin/sh
# Entrypoint script for interview-backend Spring Boot application
# Handles JVM configuration with proper environment variable expansion
# Note: MaxRAMPercentage must be a decimal value (e.g., 75.0) for Java 8

exec java \
  -XX:MaxRAMPercentage=${JVM_MAX_RAM_PERCENTAGE:-75.0} \
  -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=${JVM_MAX_GC_PAUSE_MS:-200} \
  -Djava.security.egd=file:/dev/./urandom \
  ${JAVA_OPTS} \
  -jar app.jar

