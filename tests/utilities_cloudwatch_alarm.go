package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// testCloudWatchAlarm applies the given example and asserts that an alarm exists for every key in
// alarmKeys, and a log metric filter exists for every key in logMetricFilterKeys. Alarms on
// AWS-published metrics have no filter, so they appear in alarmKeys only.
func testCloudWatchAlarm(t *testing.T, variant string, alarmKeys []string, logMetricFilterKeys []string) {
	t.Parallel()

	terraformDir := fmt.Sprintf("../examples/%s", variant)

	terraformOptions := &terraform.Options{
		TerraformDir: terraformDir,
		LockTimeout:  "5m",
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	region := getAWSRegion(t)
	accountID := getAWSAccountID(t)

	expectedARNs := map[string]string{}
	expectedNames := map[string]string{}
	for _, key := range alarmKeys {
		alarmName := fmt.Sprintf("test-app-%s-sharedtools-%s-alarm", variant, key)
		expectedNames[key] = alarmName
		expectedARNs[key] = fmt.Sprintf("arn:aws:cloudwatch:%s:%s:alarm:%s", region, accountID, alarmName)
	}

	expectedFilterNames := map[string]string{}
	for _, key := range logMetricFilterKeys {
		expectedFilterNames[key] = fmt.Sprintf("test-app-%s-sharedtools-%s-filter", variant, key)
	}

	assert.Equal(t, expectedARNs, terraform.OutputMap(t, terraformOptions, "arn"))
	assert.Equal(t, expectedNames, terraform.OutputMap(t, terraformOptions, "name"))
	assert.Equal(t, expectedFilterNames, terraform.OutputMap(t, terraformOptions, "log_metric_filter_name"))
}