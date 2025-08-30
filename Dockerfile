FROM golang:1.23.12-alpine3.20
WORKDIR /app
COPY go.mod .
RUN go mod download
COPY . .
RUN go build -o my-go-app
CMD ["./my-go-app"]
