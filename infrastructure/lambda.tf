resource "aws_iam_role" "lambda_role" {
  name               = "lambda_assume_role"
  description        = "Role to allow Lambda functions to assume"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "lambda_ddb" {
  name        = "lambda_ddb_policy"
  description = "Access to DynamoDB"
  policy      = data.aws_iam_policy_document.lambda_dynamodb_table_access.json
}

resource "aws_iam_policy" "lambda_apigw" {
  name        = "lambda_apigw_policy"
  description = "Access to API Gateway manage connections"
  policy      = data.aws_iam_policy_document.lambda_api_gateway_access.json
}

resource "aws_iam_policy" "lambda_logs" {
  name        = "lambda_logs_policy"
  description = "Access to CloudWatch Logs"
  policy      = data.aws_iam_policy_document.lambda_cloudwatch_logs.json
}

resource "aws_iam_role_policy_attachment" "ddb_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_ddb.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "apigw_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_apigw.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "logs_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_logs.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_lambda_function" "connect" {
  description   = "$connect websocket route handler"
  filename      = "${path.module}/bin/connect.zip"
  function_name = "connect"
  role          = aws_iam_role.lambda_role.arn
  handler       = "connect"

  source_code_hash = data.archive_file.connect.output_base64sha256

  runtime = var.runtime

  environment {
    variables = {
      REGION     = var.region
      TABLE_NAME = var.table_name
    }
  }
}

resource "aws_lambda_function" "disconnect" {
  description   = "$disconnect websocket route handler"
  filename      = "${path.module}/bin/disconnect.zip"
  function_name = "disconnect"
  role          = aws_iam_role.lambda_role.arn
  handler       = "disconnect"

  source_code_hash = data.archive_file.disconnect.output_base64sha256

  runtime = var.runtime

  environment {
    variables = {
      REGION     = var.region
      TABLE_NAME = var.table_name
    }
  }
}

resource "aws_lambda_function" "broadcast" {
  description   = "$default websocket route handler"
  filename      = "${path.module}/bin/broadcast.zip"
  function_name = "broadcastMessage"
  role          = aws_iam_role.lambda_role.arn
  handler       = "broadcast"

  source_code_hash = data.archive_file.broadcast.output_base64sha256

  runtime = var.runtime

  environment {
    variables = {
      REGION     = var.region
      TABLE_NAME = var.table_name
    }
  }
}

resource "aws_lambda_permission" "connect" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.connect.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

resource "aws_lambda_permission" "disconnect" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.disconnect.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

resource "aws_lambda_permission" "broadcast" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.broadcast.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}
