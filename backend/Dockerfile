FROM ubuntu:22.04

# Install Go, Git, and curl
RUN apt-get update && \
    apt-get install -y golang-go git curl && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy go.mod and go.sum first (cache dependencies)
COPY go.mod go.sum ./
RUN go mod download

# Copy all source code
COPY . .

# Build the Go binary
RUN go build -o main .

# Set environment variables
ENV DB_HOST="54.175.146.45"
ENV DB_USER="danish"
ENV DB_PASSWORD="admin123"
ENV DB_NAME="company"
ENV DB_PORT="5432"
ENV ALLOWED_ORIGINS="http://54.234.153.219:3000"

# Expose port
EXPOSE 8080

ENTRYPOINT ["go", "run", "main.go"]

