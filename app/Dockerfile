FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy go.mod first
COPY go.mod ./

# Copy source code
COPY main.go ./

# Initialize go.sum by running go mod tidy
RUN go mod tidy

# Build the binary
RUN go build -o log-generator main.go

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/log-generator .
EXPOSE 8080
CMD ["./log-generator"]
