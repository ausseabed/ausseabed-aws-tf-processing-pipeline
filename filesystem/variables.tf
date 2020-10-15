
variable "networking" {
  type = object({
    vpc_id           = string,
    pipelines_sg     = string,
    app_tier_subnets = list(string)
  })
}

variable "env" {}
