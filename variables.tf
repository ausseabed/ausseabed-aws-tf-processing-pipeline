variable "env" {
  type    = string
  default = null
}

variable "aws_region" {}

#------ storage variables

variable "local_storage_folder" {}

#-------compute variables

variable "fargate_cpu" {}
variable "fargate_memory" {}
variable "caris_caller_image" {}
variable "startstopec2_image" {}

variable "ecr_url" {}
variable "gdal_image" {}
variable "mbsystem_image" {}
variable "pdal_image" {}

variable "prod_data_s3_account_canonical_id" {
  type        = string
  description = "account number for cross-account permissions"
}
