

resource "aws_cognito_user_pool" "pool" {
  name = var.user_pool_name

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]


  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = var.recovery_mechanism_priority
    }
  }
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = "${var.cognito_domain_prefix}-isayen-cloud-design"
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_user_pool_client" "client" {
  name         = var.cognito_client_name
  user_pool_id = aws_cognito_user_pool.pool.id

  generate_secret = false

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["openid", "email", "profile"]

  callback_urls = var.cognito_callback_urls
  logout_urls   = var.cognito_logout_urls

  supported_identity_providers = ["COGNITO"]

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}