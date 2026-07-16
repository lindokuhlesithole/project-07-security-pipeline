variable "app_name" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

variable "alert_email" {
  type    = string
  default = ""
}
