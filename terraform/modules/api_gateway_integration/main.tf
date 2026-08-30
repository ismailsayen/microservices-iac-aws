resource "aws_apigatewayv2_integration" "alb_integration" {
  api_id             = var.agw_id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"

  integration_uri = "http://${var.alb_dns_name}/{proxy}"

  request_parameters = {
    "overwrite:header.X-Header-Secret" = var.alb_custom_header_secret
  }
  }


resource "aws_apigatewayv2_route" "proxy_route" {
  api_id    = var.agw_id
  route_key = "ANY /{proxy+}"

  target             = "integrations/${aws_apigatewayv2_integration.alb_integration.id}"
  authorizer_id      = var.agw_authorizer_id
  authorization_type = "JWT"
}