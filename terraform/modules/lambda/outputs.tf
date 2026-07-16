output "enrichment_arn" {
  value = aws_lambda_function.enrichment.arn
}

output "remediation_arn" {
  value = aws_lambda_function.remediation.arn
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}
