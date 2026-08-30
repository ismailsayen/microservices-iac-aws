output "link_to_log" {
  value = "https://${aws_cognito_user_pool_domain.domain.domain}.auth.eu-west-3.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.client.id}&response_type=code&scope=openid+email+profile&redirect_uri=${var.cognito_callback_urls[0]}"
}

output "user_pool_id"{
    value = aws_cognito_user_pool.pool.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.client.id
}