//resource "aws_cloudwatch_event_target" "asf" {
//  rule      = aws_cloudwatch_event_rule.trigger-processing-pipeline.name
//  target_id = "trigger-step-function"
//  arn       = var.ausseabed-processing-pipeline.id
//  role_arn  = aws_iam_role.asf_events.arn
//}
