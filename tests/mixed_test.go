package test

import (
	"testing"
)

// Both alarm kinds in one list: only the log-metric alarm gets a filter.
func TestMixedExample(t *testing.T) {
	testCloudWatchAlarm(t, "mixed", []string{"error", "target-response-time"}, []string{"error"})
}