# syntax=docker/dockerfile:1
# =============================================================================
#  Dockerfile - multi-stage build cho Spring Boot 4 / Java 21 / Gradle
# =============================================================================

# ---------- Stage 1: build - biên dịch & đóng gói bằng Gradle + JDK 21 ----------
FROM gradle:8.14-jdk21 AS build
WORKDIR /workspace

# Copy build files trước, tận dụng cache dependency layer
COPY build.gradle settings.gradle ./
RUN gradle dependencies --no-daemon

# Copy source và build jar
COPY src ./src
RUN gradle bootJar --no-daemon -x test

# ---------- Stage 2: runtime - chỉ chứa JRE 21 + file JAR ----------
FROM eclipse-temurin:21-jre-jammy AS runtime

# Phiên bản ứng dụng truyền vào lúc build
ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION} \
    JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75"

WORKDIR /app

# Chạy ứng dụng bằng user thường, không dùng root
RUN addgroup --system spring && adduser --system --ingroup spring spring
COPY --from=build /workspace/build/libs/app.jar /app/app.jar
USER spring

EXPOSE 8080

# ENTRYPOINT dạng exec (mảng JSON)
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
