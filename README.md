# pi-gen-go [![GoDoc][1]][2] [![Build Status][3]][4] [![Go Report Card][5]][6] [![Coverage Status][7]][8]
                       
[1]: https://godoc.org/github.com/dimchansky/pi-gen-go?status.svg
[2]: https://godoc.org/github.com/dimchansky/pi-gen-go
[3]: https://travis-ci.org/dimchansky/pi-gen-go.svg?branch=master
[4]: https://travis-ci.org/dimchansky/pi-gen-go
[5]: https://goreportcard.com/badge/github.com/dimchansky/pi-gen-go
[6]: https://goreportcard.com/report/github.com/dimchansky/pi-gen-go
[7]: https://codecov.io/gh/dimchansky/pi-gen-go/branch/master/graph/badge.svg
[8]: https://codecov.io/gh/dimchansky/pi-gen-go

The algorithm for generating the digits of π sequentially in pure Go.

## Example

The [simplest program](./cmd/printpi/main.go) that outputs all digits of π in an infinite loop:

```go
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
```