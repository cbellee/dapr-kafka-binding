FROM golang:1.16-alpine as builder

WORKDIR /app

COPY ./src/pub/go.mod ./
COPY ./src/pub/go.sum ./
RUN go mod download
COPY ./src/pub/*.go ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /main

FROM alpine:3.11.3

COPY --from=builder /main .
EXPOSE 8080
CMD [ "/main" ]