variable "region" {
  description = "AWS region"
  default     = "ap-southeast-1" # Singapore
}

variable "runtime" {
  description = "Lambda runtime"
  default     = "go1.x"
}

variable "table_name" {
  description = "DynamoDB table name"
  default     = "gobrol"
}
