FROM golang:1.22.5-alpine AS builder
WORKDIR /app
COPY go.mod .
RUN go mod download
COPY . .
RUN go build -o my-go-app 
EXPOSE 8080
CMD ["./my-go-app"]