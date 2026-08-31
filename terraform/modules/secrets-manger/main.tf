resource "aws_secretsmanager_secret" "this" {
  name        = var.secret_name

  recovery_window_in_days = 0

}

# Store the secret value
resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id

  secret_string = jsonencode(var.secret_values)
}