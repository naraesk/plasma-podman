package main

import (
	"context"
	"C"
	"github.com/docker/docker/api/types"
	"github.com/docker/docker/client"
)

var ctx context.Context
var cli *client.Client
var err error

func main() {
	ctx = context.Background()
	cli, err = client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	if err != nil {
		panic(err)
	}
}

//export List
func List() *C.char {
	//ctx := context.Background()
	containers, err := cli.ContainerList(ctx, types.ContainerListOptions{})
	if err != nil {
		panic(err)
	}

	for _, container := range containers {
		//fmt.Println(container.ID)
		return C.CString(container.ID)
	}
	
	return C.CString("empty")
} 
