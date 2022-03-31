
variable "networking" {
  type = object({
    vpc_id           = string,
    pipelines_sg     = string,
    app_tier_subnets = list(string)
  })
}

variable "region" {}
variable "env" {}

variable "ausseabed_sm_role" {}

variable "aws_ecs_cluster_main" {}
variable "aws_ecs_task_definition_gdal_arn" {}
variable "aws_ecs_task_definition_mbsystem_arn" {}
variable "aws_ecs_task_definition_pdal_arn" {}
variable "aws_ecs_task_definition_surveyzip_arn" {}

variable "aws_ecs_task_definition_caris_version_arn" {}
variable "aws_ecs_task_definition_startstopec2_arn" {}
variable "local_storage_folder" {}
variable "pipeline_ecs_subnet" { type = string }
variable "pipeline_ecs_app_subnets" {
  type = list
}

variable "aws_instance_caris" {}

variable "prod_data_s3_account_canonical_id" {}
