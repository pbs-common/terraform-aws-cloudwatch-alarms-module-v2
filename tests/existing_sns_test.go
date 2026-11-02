package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Alarms can be adopted under a caller-supplied name and notify targets that already exist.
// Names set via alarm_name/filter_name are used verbatim rather than generated, and alarm_actions
// are the union of the caller's ARNs and any topic this module created for that alarm.
func TestExistingSNSExample(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/existing-sns",
		LockTimeout:  "5m",
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	existingTopicARN := terraform.Output(t, terraformOptions, "existing_topic_arn")

	// alarm_name and filter_name are used verbatim; "shared-and-slack" sets neither, so it keeps
	// the generated <name>-<environment>-<alarm name>-alarm form.
	assert.Equal(t, map[string]string{
		"adopted":          "test-app-existing-sns-adopted-legacy-name",
		"shared-and-slack": "test-app-existing-sns-sharedtools-shared-and-slack-alarm",
		"log-error":        "test-app-existing-sns-sharedtools-log-error-alarm",
	}, terraform.OutputMap(t, terraformOptions, "name"))

	assert.Equal(t, map[string]string{
		"log-error": "test-app-existing-sns-log-error-legacy-filter",
	}, terraform.OutputMap(t, terraformOptions, "log_metric_filter_name"))

	adopted := getCloudWatchAlarm(t, "test-app-existing-sns-adopted-legacy-name")
	assert.Equal(t, []string{existingTopicARN}, adopted.alarmActions,
		"an alarm with no slack_channel_id should notify only the caller's targets")
	assert.Equal(t, []string{existingTopicARN}, adopted.okActions)

	// slack_channel_id is set as well, so the module's own topic joins the caller's ARN.
	sharedAndSlack := getCloudWatchAlarm(t, "test-app-existing-sns-sharedtools-shared-and-slack-alarm")
	assert.Contains(t, sharedAndSlack.alarmActions, existingTopicARN)
	assert.Len(t, sharedAndSlack.alarmActions, 2,
		"expected the caller's ARN plus the topic created for this alarm")
	assert.Empty(t, sharedAndSlack.okActions,
		"a module-created topic must not be added to ok_actions")

	logError := getCloudWatchAlarm(t, "test-app-existing-sns-sharedtools-log-error-alarm")
	assert.Empty(t, logError.alarmActions)
	assert.Equal(t, []string{existingTopicARN}, logError.okActions)
}