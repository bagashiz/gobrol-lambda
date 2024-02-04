resource "aws_apigatewayv2_api" "websocket" {
  name        = "gobrol-api"
  description = "API Gateway for Gobrol App"

  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_stage" "dev" {
  api_id      = aws_apigatewayv2_api.websocket.id
  name        = "dev"
  description = "Development Stage"

  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn

    format = jsonencode({
      requestId    = "$context.requestId",
      ip           = "$context.identity.sourceIp",
      caller       = "$context.identity.caller",
      user         = "$context.identity.user",
      requestTime  = "$context.requestTime",
      eventType    = "$context.eventType",
      routeKey     = "$context.routeKey",
      status       = "$context.status",
      connectionId = "$context.connectionId",
    })
  }

  depends_on = [aws_cloudwatch_log_group.api_gateway]
}

resource "aws_apigatewayv2_integration" "connect" {
  api_id      = aws_apigatewayv2_api.websocket.id
  description = "$connect websocket route handler integration"

  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.connect.invoke_arn

  content_handling_strategy = "CONVERT_TO_TEXT"
  passthrough_behavior      = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_integration" "disconnect" {
  api_id      = aws_apigatewayv2_api.websocket.id
  description = "$disconnect websocket route handler integration"

  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.disconnect.invoke_arn

  content_handling_strategy = "CONVERT_TO_TEXT"
  passthrough_behavior      = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_integration" "broadcast" {
  api_id      = aws_apigatewayv2_api.websocket.id
  description = "$default websocket route handler integration"

  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.broadcast.invoke_arn

  content_handling_strategy = "CONVERT_TO_TEXT"
  passthrough_behavior      = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "connect" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.connect.id}"
}

resource "aws_apigatewayv2_route" "disconnect" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.disconnect.id}"
}

resource "aws_apigatewayv2_route" "broadcast" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.broadcast.id}"
}
