# Java Hello World - multi-stage build
# stage 1: compile with the full JDK
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /build
COPY HelloWorld.java ./
RUN javac HelloWorld.java

# stage 2: run on the smaller JRE image, carrying only the compiled class
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /build/HelloWorld.class ./

EXPOSE 8080
CMD ["java", "HelloWorld"]
