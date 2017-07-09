package main

import (
	"io/ioutil"
	"log"
	"testing"
)

// TestParseResult tests the ParseFSecureOutput function.
func TestParseResult(t *testing.T) {

	r, err := ioutil.ReadFile("tests/av.virus")
	if err != nil {
		log.Fatal(err)
	}

	results := ParseAviraOutput(string(r), nil)

	if true {
		t.Log("results: ", results.Result)
	}

}
