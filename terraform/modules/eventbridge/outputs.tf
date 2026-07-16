output "api_events_rule_arn" {
  value = aws_cloudwatch_event_rule.api_events.arn
}

output "remediation_rule_arn" {
  value = aws_cloudwatch_event_rule.remediation.arn
}
