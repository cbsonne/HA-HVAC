# Mehrstufiger Build; läuft auf arm64 (Raspberry Pi 5) wie auf amd64.
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
COPY src ./src
RUN mvn -B -q -DskipTests package

FROM eclipse-temurin:21-jre-noble
WORKDIR /app
RUN useradd --system --uid 10001 app
COPY --from=build /build/target/lueftung-admin-*.jar app.jar
USER app
EXPOSE 8080
ENV JAVA_OPTS="-XX:MaxRAMPercentage=65"
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
