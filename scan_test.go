package main

import (
	"log"
	"os"
	"testing"
)

// TestParseResult tests the ParseFSecureOutput function.
func TestParseResult(t *testing.T) {

	r, err := os.ReadFile("tests/av.virus")
	if err != nil {
		log.Fatal(err)
	}

	results := ParseAviraOutput(string(r), nil)

	if true {
		t.Log("results: ", results.Result)
	}

}
