package test

import (
	"testing"
)

func TestBasicExample(t *testing.T) {
	testCloudWatchAlarm(t, "basic", []string{"error"}, []string{"error"})
}