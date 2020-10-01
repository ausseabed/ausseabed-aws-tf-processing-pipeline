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

//
//output "private_sg" {
//  value = aws_security_group.tf_private_sg.id
//}
//
//output "aws_ecs_task_definition_caris_sg"{
//  value = aws_security_group.tf_public_sg.id
//}
//
//output "subnet_ips" {
//  value = aws_subnet.tf_public_subnet.*.cidr_block
//}
//
//output "aws_ecs_task_definition_caris_subnet"{
//  value = aws_subnet.tf_public_subnet[0].id
//}