data "archive_file" "connect" {
  type        = "zip"
  source_file = "${path.module}/bin/connect"
  output_path = "${path.module}/bin/connect.zip"
}

data "archive_file" "disconnect" {
  type        = "zip"
  source_file = "${path.module}/bin/disconnect"
  output_path = "${path.module}/bin/disconnect.zip"
}

data "archive_file" "broadcast" {
  type        = "zip"
  source_file = "${path.module}/bin/broadcast"
  output_path = "${path.module}/bin/broadcast.zip"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
data "aws_iam_policy_document" "lambda_dynamodb_table_access" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]

    resources = [
      "${aws_dynamodb_table.gobrol.arn}"
    ]
  }
}

data "aws_iam_policy_document" "lambda_api_gateway_access" {
  statement {
    effect = "Allow"

    actions = [
      "execute-api:ManageConnections",
      "execute-api:Invoke"
    ]

    resources = [
      "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
    ]
  }
}

data "aws_iam_policy_document" "lambda_cloudwatch_logs" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}
