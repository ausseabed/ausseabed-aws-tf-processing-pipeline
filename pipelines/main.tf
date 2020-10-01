data "aws_caller_identity" "current" {}

locals {
  pipeline_vars = {
    "env" = var.env
    # this is CARIS manual windows box in *DEV* account (as opposed to PROD in ../compute/ module ¯\_(ツ)_/¯ )
    "region"                                    = var.region
    "account_id"                                = data.aws_caller_identity.current.account_id
    "prefix"                                    = "ga_sb_${var.env}"
    "caris_ip"                                  = "172.31.11.235"
    "ausseabed_sm_role"                         = var.ausseabed_sm_role
    "aws_ecs_cluster_arn"                       = var.aws_ecs_cluster_main.arn
    "aws_ecs_task_definition_gdal_arn"          = var.aws_ecs_task_definition_gdal_arn
    "aws_ecs_task_definition_caris_sg"          = var.networking.pipelines_sg
    "aws_ecs_task_definition_caris_subnet"      = var.networking.app_tier_subnets[0]
    "aws_ecs_task_definition_mbsystem_arn"      = var.aws_ecs_task_definition_mbsystem_arn
    "aws_ecs_task_definition_pdal_arn"          = var.aws_ecs_task_definition_pdal_arn
    "aws_ecs_task_definition_caris_version_arn" = var.aws_ecs_task_definition_caris_version_arn
    "aws_ecs_task_definition_startstopec2_arn"  = var.aws_ecs_task_definition_startstopec2_arn
    "local_storage_folder"                      = var.local_storage_folder
    "aws_step_function_process_l3_name"         = "ga-sb-${var.env}-ausseabed-processing-pipeline-l3"
    "steps" = ["Get caris version", "data quality check", "prepare change vessel config file", "Create HIPS file",
      "Import to HIPS", "Upload checkpoint 1 to s3", "Import HIPS From Auxiliary", "Upload checkpoint 2 to s3",
      "change vessel config file to calculated", "Compute GPS Vertical Adjustment", "change vessel config file to original",
      "Georeference HIPS Bathymetry", "Upload checkpoint 3 to s3", "Create Variable Resolution HIPS Grid With Cube", "Upload checkpoint 5 to s3",
    "Export raster as BAG", "Export raster as LAS"]
    "runtask"         = "\"Type\":\"Task\",\"Resource\":\"arn:aws:states:::ecs:runTask.sync\",\"ResultPath\": \"$.previous_step__result\""
    "parameters"      = "\"LaunchType\":\"FARGATE\",\"Cluster\":\"${var.aws_ecs_cluster_main.arn}\",\"TaskDefinition\":\"${var.aws_ecs_task_definition_caris_version_arn}\",\"NetworkConfiguration\":{\"AwsvpcConfiguration\":{\"AssignPublicIp\":\"ENABLED\",\"SecurityGroups\":[\"TODO\"],\"Subnets\":[\"TODO\"]}}"
    "ecs_task_prefix" = "https://${var.region}.console.aws.amazon.com/ecs/home?region=${var.region}#/clusters/${var.aws_ecs_cluster_main.cluster_name}/tasks/{0}/details"
  }
}


resource "aws_sfn_state_machine" "ausseabed-processing-pipeline-l3" {
  name     = "ga-sb-${var.env}-ausseabed-processing-pipeline-l3"
  role_arn = var.ausseabed_sm_role

  definition = templatefile("${path.module}/step_functions/process_L3.asl.json", local.pipeline_vars)
}

resource "aws_sfn_state_machine" "update-l3-warehouse" {
  name     = "ga-sb-${var.env}-update-l3-warehouse"
  role_arn = var.ausseabed_sm_role

  definition = templatefile("${path.module}/step_functions/update_L3_warehouse.asl.json", local.pipeline_vars)
}

//resource "aws_sfn_state_machine" "ausseabed-build-l0-sfn" {
//  name     = "ga-sb-${var.env}-ausseabed-build-l0-sfn"
//  role_arn = var.ausseabed_sm_role
//
//  definition = templatefile("${path.module}/build_L0_coverage.asl.json",local.pipeline_vars)
//}
//
//resource "aws_sfn_state_machine" "ausseabed-processing-pipeline_sfn_state_machine-ga" {
//  name     = "ga-sb-${var.env}-ausseabed-processing-pipeline-ga"
//  role_arn = var.ausseabed_sm_role
//  definition = templatefile("${path.module}/ga_processing_pipeline.asl.json",local.pipeline_vars)
//}
//
//resource "aws_sfn_state_machine" "ausseabed-processing-pipeline_sfn_state_machine-csiro" {
//  name     = "ga-sb-${var.env}-ausseabed-processing-pipeline-csiro"
//  role_arn = var.ausseabed_sm_role
//  definition = templatefile("${path.module}/csiro_processing_pipeline.asl.json", local.pipeline_vars)
//}
