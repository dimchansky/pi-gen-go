package main

import (
	"fmt"

	pigen "github.com/dimchansky/pi-gen-go"
)

func main() {
	g := pigen.New()
	fmt.Print(g.NextDigit())
	fmt.Print(".")
	for {
		fmt.Print(g.NextDigit())
	}
}
