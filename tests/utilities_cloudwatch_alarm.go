package test

import (
	"fmt"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/cloudwatch"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// cloudWatchAlarm holds the parts of a live alarm the tests assert on.
type cloudWatchAlarm struct {
	alarmActions []string
	okActions    []string
}

// getCloudWatchAlarm reads the named alarm back from CloudWatch. Outputs only expose ARNs and
// names, so the notification wiring has to be read from the live alarm.
func getCloudWatchAlarm(t *testing.T, alarmName string) cloudWatchAlarm {
	sess, err := session.NewSession()
	require.NoError(t, err, "failed to create AWS session")

	out, err := cloudwatch.New(sess).DescribeAlarms(&cloudwatch.DescribeAlarmsInput{
		AlarmNames: []*string{aws.String(alarmName)},
		AlarmTypes: []*string{aws.String(cloudwatch.AlarmTypeMetricAlarm)},
	})
	require.NoError(t, err, "failed to describe alarm %s", alarmName)
	require.Len(t, out.MetricAlarms, 1, "expected exactly one alarm named %s", alarmName)

	return cloudWatchAlarm{
		alarmActions: aws.StringValueSlice(out.MetricAlarms[0].AlarmActions),
		okActions:    aws.StringValueSlice(out.MetricAlarms[0].OKActions),
	}
}

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