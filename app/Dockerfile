# Stage 1: Build stage
FROM golang:1.26-alpine AS builder

# Install build dependencies if needed (e.g., git)
RUN apk add --no-cache git

WORKDIR /app

# Copy dependency files first to leverage Docker layer caching
COPY go.mod ./
RUN go mod download

# Copy source code
COPY . .

# Download dependencies and generate go.sum
RUN go mod tidy

# Build with security flags:
# - CGO_ENABLED=0: Creates a static binary (no external dependencies)
# - -ldflags="-w -s": Strips debug info to reduce size and attack surface
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o log-generator main.go


# Stage 2: Runtime stage (minimal)
FROM alpine:latest

# Security best practice: add a non-root user
RUN adduser -D appuser
USER appuser

WORKDIR /app

# Copy only the compiled binary from the builder stage
COPY --from=builder /app/log-generator .

EXPOSE 8080
CMD ["./log-generator"]