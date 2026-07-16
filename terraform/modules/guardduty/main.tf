resource "aws_guardduty_detector" "main" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = false
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = { Name = var.app_name }
}

resource "aws_guardduty_filter" "high_severity" {
  name        = "${var.app_name}-high-severity"
  action      = "ARCHIVE"
  rank        = 1
  detector_id = aws_guardduty_detector.main.id

  finding_criteria {
    criterion {
      field  = "severity"
      equals = ["7", "8"]
    }
  }
}
