# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.app_name}-alerts"
  tags = { Name = "${var.app_name}-alerts" }
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda" {
  name = "${var.app_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = { Name = "${var.app_name}-lambda-role" }
}

resource "aws_iam_role_policy" "lambda" {
  name = "${var.app_name}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          "arn:aws:dynamodb:*:*:table/${var.findings_table}",
          "arn:aws:dynamodb:*:*:table/${var.cases_table}",
          "arn:aws:dynamodb:*:*:table/${var.findings_table}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["sns:Publish"]
        Resource = aws_sns_topic.alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:RevokeSecurityGroupIngress",
          "iam:ListAccessKeys",
          "iam:UpdateAccessKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# Enrichment Lambda
resource "aws_lambda_function" "enrichment" {
  function_name = "${var.app_name}-enrichment"
  role          = aws_iam_role.lambda.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30

  filename         = data.archive_file.enrichment.output_path
  source_code_hash = data.archive_file.enrichment.output_base64sha256

  environment {
    variables = {
      FINDINGS_TABLE = var.findings_table
      CASES_TABLE    = var.cases_table
      SNS_TOPIC_ARN  = aws_sns_topic.alerts.arn
    }
  }

  tags = { Name = "${var.app_name}-enrichment" }
}

data "archive_file" "enrichment" {
  type        = "zip"
  output_path = "${path.module}/enrichment.zip"

  source {
    content  = <<-EOF
import json
import boto3
import os
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')

findings_table = dynamodb.Table(os.environ['FINDINGS_TABLE'])
cases_table = dynamodb.Table(os.environ['CASES_TABLE'])
sns_topic = os.environ['SNS_TOPIC_ARN']

def lambda_handler(event, context):
    """Process CloudTrail API events and create security findings"""

    detail = event.get('detail', {})
    event_name = detail.get('eventName', 'Unknown')
    event_source = detail.get('eventSource', 'Unknown')
    user = detail.get('userIdentity', {}).get('arn', 'Unknown')
    source_ip = detail.get('sourceIPAddress', 'Unknown')

    # Severity scoring based on event type
    severity_map = {
        'DeleteTrail': 8,
        'CreateAccessKey': 7,
        'PutBucketPolicy': 6,
        'AuthorizeSecurityGroupIngress': 5
    }
    severity = severity_map.get(event_name, 3)

    finding = {
        'findingId': f"{event_name}-{detail.get('eventID', 'unknown')}",
        'timestamp': datetime.utcnow().isoformat(),
        'type': f"CloudTrail:{event_name}",
        'severity': str(severity),
        'title': f"Suspicious API Call: {event_name}",
        'description': f"User {user} called {event_name} from {source_ip}",
        'resource': json.dumps({
            'eventSource': event_source,
            'user': user,
            'sourceIP': source_ip,
            'accountId': detail.get('userIdentity', {}).get('accountId', ''),
            'region': detail.get('awsRegion', '')
        }),
        'accountId': detail.get('userIdentity', {}).get('accountId', ''),
        'region': detail.get('awsRegion', ''),
        'enriched': True,
        'status': 'OPEN'
    }

    findings_table.put_item(Item=finding)

    # Create case for high severity
    if severity >= 6:
        case_id = f"CASE-{finding['findingId'][:8]}"
        cases_table.put_item(Item={
            'caseId': case_id,
            'findingId': finding['findingId'],
            'severity': finding['severity'],
            'status': 'PENDING',
            'createdAt': finding['timestamp'],
            'action': 'REQUIRES_APPROVAL'
        })

        sns.publish(
            TopicArn=sns_topic,
            Subject=f"Security Alert: {finding['title']}",
            Message=json.dumps({
                'caseId': case_id,
                'severity': finding['severity'],
                'title': finding['title'],
                'description': finding['description'],
                'action': 'REQUIRES_APPROVAL'
            }, indent=2)
        )

    return {
        'statusCode': 200,
        'body': json.dumps({
            'processed': 1,
            'severity': severity,
            'findingId': finding['findingId'],
            'message': 'Event processed and stored'
        })
    }
EOF
    filename = "handler.py"
  }
}

# Remediation Lambda
resource "aws_lambda_function" "remediation" {
  function_name = "${var.app_name}-remediation"
  role          = aws_iam_role.lambda.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30

  filename         = data.archive_file.remediation.output_path
  source_code_hash = data.archive_file.remediation.output_base64sha256

  environment {
    variables = {
      FINDINGS_TABLE = var.findings_table
      CASES_TABLE    = var.cases_table
    }
  }

  tags = { Name = "${var.app_name}-remediation" }
}

data "archive_file" "remediation" {
  type        = "zip"
  output_path = "${path.module}/remediation.zip"

  source {
    content  = <<-EOF
import json
import boto3
import os
from datetime import datetime

dynamodb = boto3.resource('dynamodb')

findings_table = dynamodb.Table(os.environ['FINDINGS_TABLE'])
cases_table = dynamodb.Table(os.environ['CASES_TABLE'])

def lambda_handler(event, context):
    """Review and remediate security findings"""

    # Scan for open findings
    response = findings_table.scan(
        FilterExpression='#status = :status',
        ExpressionAttributeNames={'#status': 'status'},
        ExpressionAttributeValues={':status': 'OPEN'}
    )

    remediated = 0
    for finding in response.get('Items', []):
        severity = int(finding.get('severity', 0))

        if severity <= 4:
            # Auto-remediate low severity
            findings_table.update_item(
                Key={'findingId': finding['findingId'], 'timestamp': finding['timestamp']},
                UpdateExpression='SET #status = :status, remediatedAt = :time',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={':status': 'REMEDIATED', ':time': datetime.utcnow().isoformat()}
            )
            remediated += 1

    return {
        'statusCode': 200,
        'body': json.dumps({
            'reviewed': len(response.get('Items', [])),
            'remediated': remediated,
            'message': 'Remediation review complete'
        })
    }
EOF
    filename = "handler.py"
  }
}
