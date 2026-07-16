module "cloudtrail" {
  source   = "./modules/cloudtrail"
  app_name = var.app_name
}

module "dynamodb" {
  source   = "./modules/dynamodb"
  app_name = var.app_name
}

module "lambda" {
  source         = "./modules/lambda"
  app_name       = var.app_name
  findings_table = module.dynamodb.findings_table
  cases_table    = module.dynamodb.cases_table
  alert_email    = var.alert_email
}

module "eventbridge" {
  source              = "./modules/eventbridge"
  app_name            = var.app_name
  enrichment_lambda   = module.lambda.enrichment_arn
  remediation_lambda  = module.lambda.remediation_arn
}
