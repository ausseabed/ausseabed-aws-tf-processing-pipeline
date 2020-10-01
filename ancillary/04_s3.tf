#----ancillary/main.tf

//data "aws_caller_identity" "current" {}


resource "aws_s3_bucket" "bathymetry-survey" {
  bucket = "ga-sb-${var.env}-bathymetry-survey"
}

resource "aws_s3_bucket" "processing-pipeline-support" {
  bucket = "ausseabed-processing-pipeline-${var.env}-support"
}




resource "aws_s3_bucket" "bucket-for-cloudtrail" {
  bucket        = "ga-sb-${var.env}-bucket-for-cloudtrail"
  force_destroy = true

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::ga-sb-${var.env}-bucket-for-cloudtrail"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::ga-sb-${var.env}-bucket-for-cloudtrail/prefix/AWSLogs/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

