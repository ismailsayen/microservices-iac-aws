data "terraform_remote_state" "foundation" {
  backend = "s3"

  config = {
    bucket = "cloud-architect-for-microservice-state"
    key    = "prod/foundation/terraform.tfstate"
    region = "eu-west-3"
  }
}

data "aws_secretsmanager_secret" "this" {
  name = "production-credentials"
}

data "aws_secretsmanager_secret_version" "this" {
  secret_id = data.aws_secretsmanager_secret.this.id
}
