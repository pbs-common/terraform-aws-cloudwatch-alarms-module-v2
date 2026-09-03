package test

import (
	"testing"
)

func TestNoSNSExample(t *testing.T) {
	testCloudWatchAlarm(t, "no-sns", []string{"error"}, []string{"error"})
}