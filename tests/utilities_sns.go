package test

import (
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sns"
	"github.com/stretchr/testify/require"
)

// getSNSSubscriptionEndpoints returns the endpoint of every subscription on the given topic. A
// subscription appears here as soon as it is created, regardless of whether it has been confirmed
// yet (email endpoints require a human to click the confirmation link AWS sends).
func getSNSSubscriptionEndpoints(t *testing.T, topicARN string) []string {
	sess, err := session.NewSession()
	require.NoError(t, err, "failed to create AWS session")

	out, err := sns.New(sess).ListSubscriptionsByTopic(&sns.ListSubscriptionsByTopicInput{
		TopicArn: aws.String(topicARN),
	})
	require.NoError(t, err, "failed to list subscriptions for topic %s", topicARN)

	endpoints := make([]string, 0, len(out.Subscriptions))
	for _, subscription := range out.Subscriptions {
		endpoints = append(endpoints, aws.StringValue(subscription.Endpoint))
	}
	return endpoints
}