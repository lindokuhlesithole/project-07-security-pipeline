resource "aws_dynamodb_table" "findings" {
  name         = "${var.app_name}-findings"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "findingId"
  range_key    = "timestamp"

  attribute {
    name = "findingId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "severity"
    type = "N"
  }

  global_secondary_index {
    name            = "severity-index"
    hash_key        = "severity"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  tags = { Name = "${var.app_name}-findings" }
}

resource "aws_dynamodb_table" "cases" {
  name         = "${var.app_name}-cases"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "caseId"

  attribute {
    name = "caseId"
    type = "S"
  }

  tags = { Name = "${var.app_name}-cases" }
}
