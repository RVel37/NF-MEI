FROM openjdk:11-jre-slim

WORKDIR /mobstertovcf

# Download the MobsterVCF jar directly
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*
RUN wget https://github.com/jyhehir/mobster/raw/develop/resources/MobsterVCF/MobsterVCF-0.0.1-SNAPSHOT.jar