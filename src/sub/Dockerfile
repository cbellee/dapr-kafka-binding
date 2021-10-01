FROM golang:1.16-alpine as builder

WORKDIR /app

COPY ./src/sub/go.mod ./
COPY ./src/sub/go.sum ./
RUN go mod download
COPY ./src/sub/*.go ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /main

FROM alpine:3.11.3

COPY --from=builder /main .
EXPOSE 8081
CMD [ "/main" ]