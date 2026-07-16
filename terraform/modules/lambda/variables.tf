variable "app_name" {
  type = string
}

variable "findings_table" {
  type = string
}

variable "cases_table" {
  type = string
}

variable "alert_email" {
  type    = string
  default = ""
}
