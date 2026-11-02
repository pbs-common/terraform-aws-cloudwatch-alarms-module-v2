package test

import (
	"testing"
)

// The alarm is on an AWS-published metric, so no log metric filter should be created.
func TestAWSMetricExample(t *testing.T) {
	testCloudWatchAlarm(t, "aws-metric", []string{"target-response-time"}, []string{})
}