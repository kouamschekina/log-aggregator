FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod ./
COPY main.go ./
RUN go build -o log-generator main.go

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/log-generator .
CMD ["./log-generator"]
