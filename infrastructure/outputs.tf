output "url" {
  description = "Base URL"
  value       = aws_apigatewayv2_stage.dev.invoke_url
}
