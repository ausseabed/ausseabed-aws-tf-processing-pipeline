

#temporary resource, until we figure out what specific access is actually required
resource "aws_security_group" "pipeline_default_sg" {
  name        = "tf_public_sg"
  description = "Used for access to the public instances"
  vpc_id      = var.networking.vpc_id


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

