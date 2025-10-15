FROM ubuntu:22.04

# Install Go, Git, and any dependencies
RUN apt-get update && \
    apt-get install -y golang-go git curl && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the rest of the source code
COPY . .

ENV DB_HOST="54.198.53.74" \
    DB_USER="danish" \
    DB_PASSWORD="admin123" \
    DB_NAME="company" \
    DB_PORT="5432" \
    ALLOWED_ORIGINS="http://54.227.85.108:3000"

RUN go get ./...

# Expose the backend port
EXPOSE 8080


ENTRYPOINT ["go", "run", "main.go"]
