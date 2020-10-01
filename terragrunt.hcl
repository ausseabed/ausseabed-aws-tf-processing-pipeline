locals {
  s3_backend_role_arns = map(
  "831535125571", "arn:aws:iam::007391679308:role/ga-aws-ausseabed-prod-terraform",
  "288871573946", "arn:aws:iam::007391679308:role/ga-aws-ausseabed-dev-terraform",
  )
  s3_backend_keys      = map(
  "831535125571", "env:/prod/terraform/processing-pipeline-infra/processing-pipeline-infra.tfstate",
  "288871573946", "terraform/processing-pipeline-infra/processing-pipeline-infra.tfstate"
  )

  envs = map(
  "831535125571", "prod",
  "288871573946", "default"
  )

  ecr_urls = map (
  "288871573946", "288871573946.dkr.ecr.ap-southeast-2.amazonaws.com",
  "831535125571", "007391679308.dkr.ecr.ap-southeast-2.amazonaws.com"
  )


  s3_backend_role_arn = local.s3_backend_role_arns[get_aws_account_id()]
  s3_backend_key      = local.s3_backend_keys[get_aws_account_id()]
  env                 = local.envs[get_aws_account_id()]

  ecr_url = local.ecr_urls[get_aws_account_id()]
}

inputs = {
  env = local.env
  ecr_url = local.ecr_url
}

terraform {


  before_hook "before_hook" {
    commands = [
      "apply",
      "plan"]
    execute  = [
      "echo",
      "Using S3 backend key `${local.s3_backend_key}` using assumed role: `${local.s3_backend_role_arn}`"]
  }
}


remote_state {
  backend  = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }

  config = {
    bucket   = "ausseabed-terraform-all"
    region   = "ap-southeast-2"
    key      = "${local.s3_backend_key}"
    role_arn = "${local.s3_backend_role_arn}"
  }
}

