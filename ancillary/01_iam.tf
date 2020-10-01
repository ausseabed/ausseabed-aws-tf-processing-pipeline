#----ancillary/main.tf
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_iam_role" "ga_sb_pp_sfn_role" {
  name = "ga_sb_${var.env}_pp_sfn_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy" "ga_sb_pp_sfn_policy" {
  name = "ga_sb_${var.env}_pp_sfn_policy"
  role = aws_iam_role.ga_sb_pp_sfn_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecs:RunTask"
            ],
            "Resource": [
                "arn:aws:ecs:${var.region}:${local.account_id}:task-definition/*"
            ]
        },
         {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": [
                "arn:aws:lambda:${var.region}:${local.account_id}:function:getResumeFromStep:$LATEST",
                "arn:aws:lambda:${var.region}:${local.account_id}:function:ga_sb_${var.env}_identify_instrument_files:$LATEST",
                "arn:aws:lambda:${var.region}:${local.account_id}:function:ga_sb_${var.env}_identify_unprocessed_grids:$LATEST"
            ]
        },
        {
            "Sid": "forCloudWatch",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogDelivery",
                "logs:GetLogDelivery",
                "logs:UpdateLogDelivery",
                "logs:ListLogDeliveries",
                "logs:PutResourcePolicy",
                "logs:DescribeResourcePolicies",
                "logs:DescribeLogGroups",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "states:StartExecution"
            ],
            "Resource": [
                "arn:aws:states:${var.region}:${local.account_id}:stateMachine:ga-sb-${var.env}-ausseabed-processing-pipeline-l3"
            ]
        },        
        {
            "Effect": "Allow",
            "Action": [
                "ecs:StopTask",
                "ecs:DescribeTasks"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "events:PutTargets",
                "events:PutRule",
                "events:DescribeRule"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*"
        }
    ]
}
EOF
}



#------------- execution role arn -------------------

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ga_sb_${var.env}_ecs_task_execution_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name = "ga_sb_${var.env}_ecs_task_execution_policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "GAS3ReadWrite",
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3:PutObj*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },{
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": "arn:aws:secretsmanager:${var.region}:${local.account_id}:secret:caris_batch_secret-OMZKQN"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "secretsmanager:GetRandomPassword",
            "Resource": "*"
        },{
            "Sid": "startstopec2",
            "Effect": "Allow",
            "Action": [
                "ec2:StartInstances",
                "ec2:StopInstances"
            ],
            "Resource": "arn:aws:ec2:${var.region}:${local.account_id}:instance/*"
        },{
            "Sid": "startstopec2FindInstance",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}


resource "aws_iam_role" "asf_events" {
  name = "ga_sb_${var.env}_asf_events"

  assume_role_policy = <<DOC
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
DOC
}

// assigning premission to the role
resource "aws_iam_role_policy" "asf_events_run_task_with_any_role" {
  name = "ga_sb_${var.env}_asf_run_task_with_any_role"
  role = aws_iam_role.asf_events.id

  policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "states:StartExecution"
            ],
            "Resource": [
                "arn:aws:states:${var.region}:${local.account_id}:stateMachine:ausseabed-processing-pipeline"
            ]
        }
    ]
}
DOC
}

resource "aws_iam_role" "ec2_instance_s3" {
  name = "ga_sb_${var.env}_ec2_instance_s3"

  assume_role_policy = <<DOC
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
DOC
}

resource "aws_iam_role_policy" "s3_read_write" {
  name = "ga_sb_${var.env}_s3_read_write"
  role = aws_iam_role.ec2_instance_s3.id

  policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
       {
            "Sid": "GAS3ReadWrite",
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3:PutObj*",
                "s3:DeleteObj"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
DOC
}

resource "aws_iam_instance_profile" "ec2_instance_s3_profile" {
  name = "ga_sb_${var.env}_ec2_instance_s3_profile"
  role = aws_iam_role.ec2_instance_s3.name
}


resource "aws_iam_role" "identify_instrument_files-lambda-role" {
  name = "ga_sb_${var.env}_id_instrument_files-lambda-role"

  assume_role_policy = <<DOC
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
DOC
}

resource "aws_iam_role_policy" "identify_instrument_files-lambda-role-policy" {
  name   = "ga_sb_${var.env}_idy_instrument_files-policy"
  role   = aws_iam_role.identify_instrument_files-lambda-role.id
  policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "forCloudwatch",
            "Effect": "Allow",
            "Action": [
              "logs:CreateLogGroup",
              "logs:CreateLogDelivery",
              "logs:GetLogDelivery",
              "logs:UpdateLogDelivery",
              "logs:ListLogDeliveries",
              "logs:PutResourcePolicy",
              "logs:DescribeResourcePolicies",
              "logs:DescribeLogGroups"
            ],
            "Resource": "arn:aws:logs:${var.region}:${local.account_id}:*"
        },
        {
            "Sid": "forCloudtrail",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:${var.region}:${local.account_id}:log-group:/aws/lambda/ga_sb_${var.env}_identify_unprocessed_grids:*"
        },
        {
            "Sid": "forStepFunctions",
            "Effect": "Allow",
            "Action": [
                "states:ListStateMachines",
                "states:ListActivities",
                "states:ListExecutions",
                "states:GetExecutionHistory",
                "states:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "GAS3Read",
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": [
                "arn:aws:secretsmanager:${var.region}:${local.account_id}:secret:wh-infra.auto.tfvars*"
            ]
        }
    ]
}
DOC
}

resource "aws_iam_role" "getResumeFromStep-lambda-role" {
  name = "ga_sb_${var.env}_getResumeFromStep-lambda-role"

  assume_role_policy = <<DOC
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
DOC
}

resource "aws_iam_role_policy" "getResumeFromStep-lambda-role-policy" {
  name = "ga_sb_${var.env}_getResumeFromStep-lambda-role-policy"
  role = aws_iam_role.getResumeFromStep-lambda-role.id

  policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "forCloudtrail",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:${var.region}:${local.account_id}:log-group:/aws/lambda/getResumeFromStep:*"
        },
        {
            "Sid": "forStepFunctions",
            "Effect": "Allow",
            "Action": [
                "states:ListStateMachines",
                "states:ListActivities",
                "states:ListExecutions",
                "states:GetExecutionHistory",
                "states:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "forCloudwatch",
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:${var.region}:${local.account_id}:*"
        }
    ]
}
DOC
}
