resource "aws_iam_role" "lambda_exec" {
  name               = var.role
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_lambda_function" "main" {
  description   = "Main Lambda Function"
  filename      = "${path.module}/bin/main.zip"
  function_name = "main"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "main"

  source_code_hash = data.archive_file.main.output_base64sha256

  runtime = var.runtime

  environment {
    variables = {}
  }
}

resource "aws_lambda_permission" "main" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
