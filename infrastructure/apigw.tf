resource "aws_apigatewayv2_api" "main" {
  name          = "gobrol-api"
  protocol_type = "HTTP"
  description   = "API for Gobrol Lambda"
}

resource "aws_apigatewayv2_stage" "dev" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "dev"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn

    format = jsonencode({
      requestId               = "$context.requestId",
      sourceIp                = "$context.identity.sourceIp",
      requestTime             = "$context.requestTime",
      protocol                = "$context.protocol",
      httpMethod              = "$context.httpMethod",
      resourcePath            = "$context.resourcePath",
      routeKey                = "$context.routeKey",
      status                  = "$context.status",
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }
}

resource "aws_apigatewayv2_integration" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  description = "Lambda hello world integration"

  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.main.invoke_arn
}

resource "aws_apigatewayv2_route" "main" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.main.id}"
}
