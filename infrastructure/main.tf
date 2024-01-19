data "archive_file" "main" {
  type        = "zip"
  source_file = "${path.module}/bin/main"
  output_path = "${path.module}/bin/main.zip"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
