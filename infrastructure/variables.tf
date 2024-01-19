variable "region" {
  description = "AWS region"
  default     = "ap-southeast-1" # Singapore
}

variable "runtime" {
  description = "Lambda runtime"
  default     = "go1.x"
}

variable "role" {
  description = "IAM role for Lambda functions"
  default     = "lambda_exec_role"
}
