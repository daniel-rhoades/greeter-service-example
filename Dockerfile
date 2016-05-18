# Lightweight Linux distro with an Oracle JDK 8 installation
FROM frolvlad/alpine-oraclejdk8:slim

MAINTAINER Daniel Rhoades <daniel@danielrhoades.com>

# Create a user to run the microservice
RUN adduser -S microservice

WORKDIR /home/microservice

# Copy the microservice to the image
COPY target/scala-2.11/greeter-service-example-assembly-0.1.jar /home/microservice/

EXPOSE 9000

# Run the microservice
USER microservice
CMD ["java", "-jar", "greeter-service-example-assembly-0.1.jar"]