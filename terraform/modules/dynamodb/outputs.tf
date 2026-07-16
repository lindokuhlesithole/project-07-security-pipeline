output "findings_table" {
  value = aws_dynamodb_table.findings.name
}

output "cases_table" {
  value = aws_dynamodb_table.cases.name
}
