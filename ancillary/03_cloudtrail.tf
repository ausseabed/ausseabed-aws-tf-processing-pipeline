#----ancillary/main.tf

resource "aws_cloudtrail" "raw-data-available-in-bathymetry-survey-trail" {
  name                          = "ga-sb-${var.env}-raw-data-available-in-bathymetry-survey-trail"
  s3_bucket_name                = aws_s3_bucket.bucket-for-cloudtrail.id
  s3_key_prefix                 = "prefix"

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type = "AWS::S3::Object"

      # Make sure to append a trailing '/' to your ARN if you want
      # to monitor all objects in a bucket.
      values = ["${aws_s3_bucket.bathymetry-survey.arn}/.done"]
    }
  }
}
