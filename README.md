# Real-Time Security Event Pipeline (SIEM Lite)

A cloud-native security operations platform built on **AWS CloudTrail**, **EventBridge**, **Lambda**, and **DynamoDB** that ingests API activity, scores security events, and routes alerts based on severity.

## Architecture

```
CloudTrail → EventBridge → Lambda (Enrichment) → DynamoDB → SNS (Alerts)
                                    ↓
                              Lambda (Remediation)
```

| Stage | Action |
|-------|--------|
| **Detect** | CloudTrail logs API activity |
| **Route** | EventBridge captures suspicious events |
| **Enrich** | Lambda scores severity, stores in DynamoDB |
| **Alert** | High severity → SNS notification |
| **Case** | DynamoDB tracks every action |

## Infrastructure

| Component | Technology |
|-----------|------------|
| **Audit Logging** | AWS CloudTrail |
| **Event Routing** | Amazon EventBridge |
| **Processing** | AWS Lambda (Python 3.11) |
| **Data Store** | DynamoDB (Pay-per-request) |
| **Alerting** | Amazon SNS |
| **IaC** | Terraform |

## Deployment

```bash
cd terraform
terraform init
terraform apply
```

## Test the Pipeline

```bash
# Trigger a suspicious API call (e.g., create an access key)
aws iam create-access-key --user-name test-user

# Or modify a security group
aws ec2 authorize-security-group-ingress   --group-id sg-xxxxx   --protocol tcp --port 22 --cidr 0.0.0.0/0
```

Check the DynamoDB table and SNS topic for alerts.

## Components

### Enrichment Lambda
- Receives CloudTrail events via EventBridge
- Scores severity based on API call type
- Stores findings in DynamoDB
- Creates cases for high-severity events
- Sends SNS alerts for critical issues

### Remediation Lambda
- Triggered hourly via EventBridge schedule
- Auto-remediates low-severity findings
- Closes resolved cases in DynamoDB

### DynamoDB Tables
- `findings` — All security events with severity index
- `cases` — Case management for tracking actions

## Cost

| Component | Monthly Cost |
|-----------|-------------|
| CloudTrail | ~$2 (first trail free) |
| Lambda | ~$2 |
| DynamoDB | ~$3 |
| SNS | ~$1 |
| **Total** | **~$8/month** |

## Cleanup

```bash
terraform destroy -auto-approve
```## Author

**Lindokuhle Sithole** - *Cloud Engineer | Cloud DevOps Engineer | Cloud Security Specialist*

Based in Bremen, Germany. BSc Mathematical Science from the University of the Witwatersrand. 5x AWS Certified (Solutions Architect Professional, Security Specialty, CloudOps Engineer Associate, Solutions Architect Associate, Cloud Practitioner) plus CompTIA Security+.

- **LinkedIn:** [linkedin.com/in/lindokuhle-sithole-bb701b19a](https://www.linkedin.com/in/lindokuhle-sithole-bb701b19a)
- **GitHub:** [github.com/lindokuhlesithole](https://github.com/lindokuhlesithole)
- **Email:** sitholelindokuhle371@gmail.com