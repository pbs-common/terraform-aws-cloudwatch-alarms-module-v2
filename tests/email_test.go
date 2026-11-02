package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// email_addresses subscribes emails to the topic this module creates for the alarm, whether or
// not slack_channel_id is also set — "email-only" has no Slack channel at all, and still gets its
// own topic solely to carry the subscriptions. AWS requires each address to confirm via a link
// Terraform cannot click, so this only asserts the subscription (and its endpoint) exists, not
// that it has been confirmed.
func TestEmailExample(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/email",
		LockTimeout:  "5m",
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	topicARNs := terraform.OutputMap(t, terraformOptions, "sns_topic_arn")

	assert.Equal(t,
		[]string{"ops-oncall@example.com"},
		getSNSSubscriptionEndpoints(t, topicARNs["shared-and-slack"]),
	)
	assert.ElementsMatch(t,
		[]string{"ops-oncall@example.com", "on-call-pager@example.com"},
		getSNSSubscriptionEndpoints(t, topicARNs["email-only"]),
	)
}