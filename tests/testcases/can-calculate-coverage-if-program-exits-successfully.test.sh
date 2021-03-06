tests:put "$_go_path/main.go" <<GO
package main

import "fmt"
import "os"

var exit = os.Exit

func main() {
    fmt.Println("coverage!")
}
GO

tests:ensure go-test:build "$(tests:get-tmp-dir)/bin/test-binary"

tests:ensure go-test:run "test-binary"
tests:assert-stdout "coverage!"

tests:ensure go-test:merge-coverage "coverage"

tests:ensure make coverage.report
tests:assert-stdout-re "main.go.*main.*100.0%"

tests:ensure make coverage.total
tests:assert-stdout "100%"
