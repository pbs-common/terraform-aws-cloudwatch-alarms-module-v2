package test

import (
	"testing"
)

func TestNoSNSExample(t *testing.T) {
	testCloudWatchAlarm(t, "no-sns")
}
