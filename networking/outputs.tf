#-----networking/outputs.tf

output "public_subnets" {
  value = data.aws_subnet_ids.web_tier_subnets
}

output "private_subnets" {
  value = data.aws_subnet_ids.app_tier_subnets
}

output "vpc_id" {
  value = data.aws_vpc.ga_sb_vpc.id
}

output "app_tier_subnets" {
  value = data.aws_subnet_ids.app_tier_subnets.ids
}


output "pipelines_sg" {
  value = aws_security_group.ga_sb_env_pipelines_sg.id
}
