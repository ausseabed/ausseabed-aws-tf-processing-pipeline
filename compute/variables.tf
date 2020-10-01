#------compute/variables.tf
variable "env" {}

variable "fargate_cpu" {}
variable "fargate_memory" {}
variable "caris_caller_image" {}
variable "gdal_image" {}
variable "mbsystem_image" {}
variable "pdal_image" {}
variable "startstopec2_image" {}
variable "ecs_task_execution_role_arn" {}

variable "prod_data_s3_account_canonical_id" {}

