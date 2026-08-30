output "agw_id" {
  value = aws_apigatewayv2_api.http_api.id
}

output "api_gateway_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}