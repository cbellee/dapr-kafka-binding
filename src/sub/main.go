package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/dapr/go-sdk/service/common"
	daprd "github.com/dapr/go-sdk/service/http"
)

func main() {
	log.Print("### Dapr: starting...")

	port := os.Getenv("APP_PORT")
	s := daprd.NewService(":" + port)

	log.Print("### Dapr: adding binding event handler...")
	if err := s.AddBindingInvocationHandler("/neworder", orderHandler); err != nil {
		log.Fatalf("error adding binding handler: %v", err)
	}

	if err := s.Start(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("error listenning: %v", err)
	} else {
		fmt.Printf("server listening on port: %s", port)
	}
}

func orderHandler(ctx context.Context, in *common.BindingEvent) (out []byte, err error) {
	fmt.Printf("binding - Data:%s, Meta:%v", in.Data, in.Metadata)
	return nil, nil
}
