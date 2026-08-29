# 构建阶段
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
# 使用阿里云镜像加速依赖下载
COPY settings-docker.xml /root/.m2/settings.xml
COPY pom.xml .
RUN mvn -B dependency:go-offline
COPY src ./src
RUN mvn -B package -DskipTests

# 运行阶段
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
