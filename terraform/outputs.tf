output "cloudtrail_arn" {
  value = module.cloudtrail.trail_arn
}

output "log_bucket" {
  value = module.cloudtrail.bucket_name
}

output "findings_table" {
  value = module.dynamodb.findings_table
}

output "cases_table" {
  value = module.dynamodb.cases_table
}

output "sns_topic_arn" {
  value = module.lambda.sns_topic_arn
}

output "enrichment_lambda" {
  value = module.lambda.enrichment_arn
}

output "remediation_lambda" {
  value = module.lambda.remediation_arn
}
