# EventBridge Rule for CloudTrail API events
resource "aws_cloudwatch_event_rule" "api_events" {
  name        = "${var.app_name}-api-events"
  description = "Capture suspicious API activity from CloudTrail"

  event_pattern = jsonencode({
    source      = ["aws.cloudtrail"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = ["CreateAccessKey", "DeleteTrail", "PutBucketPolicy", "AuthorizeSecurityGroupIngress"]
    }
  })

  tags = { Name = "${var.app_name}-api-events" }
}

resource "aws_cloudwatch_event_target" "enrichment" {
  rule      = aws_cloudwatch_event_rule.api_events.name
  target_id = "enrichment"
  arn       = var.enrichment_lambda
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.enrichment_lambda
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.api_events.arn
}

# Scheduled remediation review
resource "aws_cloudwatch_event_rule" "remediation" {
  name                = "${var.app_name}-remediation-schedule"
  description         = "Trigger remediation review every hour"
  schedule_expression = "rate(1 hour)"
  tags                = { Name = "${var.app_name}-remediation" }
}

resource "aws_cloudwatch_event_target" "remediation" {
  rule      = aws_cloudwatch_event_rule.remediation.name
  target_id = "remediation"
  arn       = var.remediation_lambda
}

resource "aws_lambda_permission" "remediation_eventbridge" {
  statement_id  = "AllowEventBridgeRemediation"
  action        = "lambda:InvokeFunction"
  function_name = var.remediation_lambda
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.remediation.arn
}
