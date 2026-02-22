package main

import (
	"context"
	"C"
	"github.com/docker/docker/api/types/container"
	"github.com/docker/docker/api/types/filters"
	"github.com/docker/docker/client"
	"fmt"
)

/*var ctx context.Context
var cli *client.Client
var err error*/

func main() {
	/*ctx = context.Background()
	cli, err = client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	if err != nil {
		panic(err)
	}*/
	
	fmt.Println(List())
}

//export List
func List() *C.char {
	ctx := context.Background()
	cli, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	if err != nil {
		panic(err)
	}
	
	filters := filters.NewArgs()
	filters.Add("label", "com.docker.compose.project.working_dir")
	
	containers, err := cli.ContainerList(ctx, container.ListOptions{
		Size:   true,
		All:    true,
		Since:  "container",
		Filters: filters,
	})
	if err != nil {
		panic(err)
	}

	for _, container := range containers {
		fmt.Println(container)
		return C.CString(container.ID)
	}
	
	return C.CString("empty")
} 
