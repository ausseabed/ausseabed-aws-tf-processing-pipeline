#----ancillary/main.tf


resource "aws_cloudwatch_log_group" "caris-version" {
  name = "/ecs/ga_sb_${var.env}_caris-version"

  tags = {
    Environment = "poc"
    Application = "caris"
  }
}

resource "aws_cloudwatch_log_group" "startstopec2" {
  name = "/ecs/ga_sb_${var.env}_startstopec2"

  tags = {
    Environment = "poc"
    Application = "caris"
  }
}

resource "aws_cloudwatch_log_group" "containers" {
  name = "/ecs/ga_sb_${var.env}_containers"

  tags = {
    Environment = "poc"
    Application = "gdal"
  }
}


resource "aws_cloudwatch_log_group" "lambda_function" {
  name = "/aws/lambda/ga_sb_${var.env}_identify_unprocessed_grids"

  tags = {
    Environment = "lambda"
    Application = "stepfunction"
  }
}


resource "aws_cloudwatch_event_rule" "trigger-processing-pipeline" {
  name        = "ga_sb_${var.env}-trigger-processing-pipeline"
  description = "trigger-processing-pipeline on s3 event"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.s3"
  ],
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "s3.amazonaws.com"
    ],
    "eventName": [
      "PutObject"
    ],
    "requestParameters": {
      "bucketName": [
        "bathymetry-survey-288871573946"
      ]
    }
  }
}
PATTERN
}

