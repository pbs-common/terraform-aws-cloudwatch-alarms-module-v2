package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func testCloudWatchAlarm(t *testing.T, variant string) {
	t.Parallel()

	terraformDir := fmt.Sprintf("../examples/%s", variant)

	terraformOptions := &terraform.Options{
		TerraformDir: terraformDir,
		LockTimeout:  "5m",
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	arn := terraform.OutputMap(t, terraformOptions, "arn")
	name := terraform.OutputList(t, terraformOptions, "name")

	region := getAWSRegion(t)
	accountID := getAWSAccountID(t)

	expectedName := fmt.Sprintf("test-app-%s-sharedtools-error-alarm", variant)
	expectedARN := fmt.Sprintf("arn:aws:cloudwatch:%s:%s:alarm:%s", region, accountID, expectedName)
	expectedARNMap := map[string]string{"error": expectedARN}

	assert.Equal(t, expectedARNMap, arn)
	assert.Equal(t, expectedName, extractErrorValue(name[0]))
}

func extractErrorValue(s string) string {
	prefix := "map[error:"
	if strings.HasPrefix(s, prefix) && strings.HasSuffix(s, "]") {
		return strings.TrimSuffix(strings.TrimPrefix(s, prefix), "]")
	}
	return s
}
