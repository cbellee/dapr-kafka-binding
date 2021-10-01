package main

import (
	"context"
	"fmt"
	"time"

	dapr "github.com/dapr/go-sdk/client"
)

var (
	bindingName = "kafka.binding"
	operation   = "create"
)

func main() {
	ctx := context.Background()
	client, err := dapr.NewClient()
	if err != nil {
		panic(err)
	}
	defer client.Close()

	for {
		data := []byte(time.Now().String())
		br := &dapr.InvokeBindingRequest{
			Name:      bindingName,
			Operation: operation,
			Data:      data,
		}

		fmt.Printf("invoking binding: '%s' operation: '%s' data: '%s' \n", bindingName, operation, data)

		_, err := client.InvokeBinding(ctx, br)
		if err != nil {
			panic(err)
		} else {
			fmt.Printf("data published: %s", data)
		}

		time.Sleep(5 * time.Second)
	}
}
