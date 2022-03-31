locals {
  env = (var.env != null) ? var.env : terraform.workspace

  # Making sure that EFS Share provisioned in the same designated subnet step functions use to run ECS Tasks in
  pipeline_ecs_subnet = tolist(module.networking.app_tier_subnets)[0]

}

provider "aws" {
  region  = var.aws_region
  version = "2.68"
}

module "ancillary" {
  source = "./ancillary"
  env    = local.env
  region = var.aws_region
}

module "networking" {
  source = "./networking"
  env    = local.env

}

module "filesystem" {
  source              = "./filesystem"
  env                 = local.env
  networking          = module.networking
  pipeline_ecs_subnet = local.pipeline_ecs_subnet

}

module "ec2" {
  source        = "./ec2"
  env           = local.env
  aws_region    = var.aws_region
  caris_ami     = var.caris_ami
  caris_ec2_iip = module.ancillary.caris_ec2_iip
  caris_sg      = module.networking.caris_sg
}

module "compute" {
  source                            = "./compute"
  env                               = local.env
  fargate_cpu                       = var.fargate_cpu
  fargate_memory                    = var.fargate_memory
  caris_caller_image                = var.caris_caller_image
  startstopec2_image                = var.startstopec2_image
  gdal_image                        = "${var.ecr_url}/${var.gdal_image}"
  mbsystem_image                    = "${var.ecr_url}/${var.mbsystem_image}"
  pdal_image                        = "${var.ecr_url}/${var.pdal_image}"
  surveyzip_image                   = "${var.ecr_url}/${var.surveyzip_image}"
  gdal_efs                          = module.filesystem.gdal_efs
  ecs_task_execution_role_arn       = module.ancillary.ecs_task_execution_role_arn
  prod_data_s3_account_canonical_id = var.prod_data_s3_account_canonical_id
}

module "pipelines" {
  source                                    = "./pipelines"
  env                                       = local.env
  networking                                = module.networking
  ausseabed_sm_role                         = module.ancillary.ga_sb_pp_sfn_role
  aws_ecs_cluster_main                      = module.compute.aws_ecs_cluster_main
  aws_ecs_task_definition_gdal_arn          = module.compute.aws_ecs_task_definition_gdal_arn
  aws_ecs_task_definition_mbsystem_arn      = module.compute.aws_ecs_task_definition_mbsystem_arn
  aws_ecs_task_definition_pdal_arn          = module.compute.aws_ecs_task_definition_pdal_arn
  aws_ecs_task_definition_surveyzip_arn     = module.compute.aws_ecs_task_definition_surveyzip_arn
  pipeline_ecs_subnet                       = local.pipeline_ecs_subnet
  pipeline_ecs_app_subnets                  = module.networking.app_tier_subnets
  aws_instance_caris                        = module.ec2.aws_instance_caris
  aws_ecs_task_definition_caris_version_arn = module.compute.aws_ecs_task_definition_caris-version_arn
  aws_ecs_task_definition_startstopec2_arn  = module.compute.aws_ecs_task_definition_startstopec2_arn
  local_storage_folder                      = var.local_storage_folder
  region                                    = var.aws_region
  prod_data_s3_account_canonical_id         = var.prod_data_s3_account_canonical_id
}

module "get_resume_lambda_function" {
  source = "git@github.com:ausseabed/terraform-aws-lambda-builder.git"

  # Standard aws_lambda_function attributes.
  function_name = "ga_sb_${local.env}-getResumeFromStep"
  handler       = "getResumeFromStep.lambda_handler"
  runtime       = "python3.6"
  timeout       = 30
  role          = module.ancillary.getResumeFromStep_role
  create_role   = true
  enabled       = true

  # Enable build functionality.
  build_mode = "FILENAME"
  source_dir = "${path.module}/src/lambda/resume_from_step"
  filename   = "./lambda_compiler_out/getResumeFromStep.py"

  # Create and use a role with CloudWatch Logs permissions.
  role_cloudwatch_logs = true
}

module "process_l2_functions" {
  source = "git@github.com:ausseabed/terraform-aws-lambda-builder.git"

  # Standard aws_lambda_function attributes.
  function_name = "ga_sb_${local.env}-process-l2-functions"
  handler       = "process_l2_functions.lambda_handler"
  runtime       = "python3.6"
  timeout       = 30
  role          = module.ancillary.process_l2_role
  create_role   = true
  enabled       = true

  # Enable build functionality.
  build_mode = "FILENAME"
  source_dir = "${path.module}/src/lambda/process_l2_functions"
  filename   = "./lambda_compiler_out/process_l2_functions.py"

  # Create and use a role with CloudWatch Logs permissions.
  role_cloudwatch_logs = true
}

module "identify_instrument_lambda_function" {
  source = "github.com/ausseabed/terraform-aws-lambda-builder"

  # Standard aws_lambda_function attributes.
  function_name = "ga_sb_${local.env}_identify_instrument_files"
  handler       = "identify_instrument_files.lambda_handler"
  runtime       = "python3.6"
  timeout       = 300
  role          = module.ancillary.identify_instrument_files_role
  create_role   = true
  enabled       = true

  # Enable build functionality.
  build_mode = "FILENAME"
  source_dir = "${path.module}/src/lambda/identify_instrument_files"
  filename   = "./lambda_compiler_out/identify_instrument_files.py"

  # Create and use a role with CloudWatch Logs permissions.
  role_cloudwatch_logs = true
}

module "identify_unprocessed_grids_lambda_function" {
  source = "github.com/ausseabed/terraform-aws-lambda-builder?ref=feature%2Fcompile_output_dir"

  # Standard aws_lambda_function attributes.
  function_name = "ga_sb_${local.env}_identify_unprocessed_grids"
  handler       = "identify_unprocessed_grids.lambda_handler"
  runtime       = "python3.6"
  timeout       = 300
  role          = module.ancillary.identify_instrument_files_role
  create_role   = true
  enabled       = true

  # Enable build functionality.
  build_mode         = "LAMBDA"
  source_dir         = "${path.module}/src/lambda/identify_unprocessed_grids"
  # filename   = "identify_unprocessed_grids.py"
  s3_bucket          = "ausseabed-processing-pipeline-${local.env}-support"
  compile_output_dir = "./lambda_compiler_out"

  # Create and use a role with CloudWatch Logs permissions.
  role_cloudwatch_logs = true
}
