# output "secret" {
#   value = "${aws_iam_access_key.circleci.encrypted_secret}"
# }

output "ga_sb_pp_sfn_role" {
  value = aws_iam_role.ga_sb_pp_sfn_role.arn
}


output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

output "getResumeFromStep_role"{
  value = aws_iam_role.getResumeFromStep-lambda-role.arn
}

output "identify_instrument_files_role"{
  value = aws_iam_role.identify_instrument_files-lambda-role.arn
}
