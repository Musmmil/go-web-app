FROM golang:tip-alpine3.22
WORKDIR /app
COPY go.mod .
RUN go mod download
COPY . .
RUN go build -o my-go-app
CMD ["./my-go-app"]

