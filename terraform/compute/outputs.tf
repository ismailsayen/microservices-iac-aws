output "vpc_id" {
  value = data.terraform_remote_state.foundation.outputs.vpc_id
}
