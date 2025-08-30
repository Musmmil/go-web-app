# Build stage
FROM tip-alpine3.22
WORKDIR /app
COPY go.mod .
RUN go mod download
COPY . .
RUN go build -o my-go-app

# Final stage
FROM alpine:3.22.1
WORKDIR /app
COPY --from=builder /app/my-go-app .
CMD ["./my-go-app"]
