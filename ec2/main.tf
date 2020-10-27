
data "aws_subnet" "app_tier_subnet" {
  filter {
    name   = "tag:Name"
    values = ["ga_sb_${var.env}_vpc_app_1"]
  }
}

# Key should be GaSbAllCarisL2Pipeline
# aws ec2 create-key-pair --key-name GaSbAllCarisL2Pipeline --query 'KeyMaterial'  --output text > GaSbAllCarisL2Pipeline.pem
# in secrets manager
resource "aws_instance" "app_tier_instance" {
  ami           = var.caris_ami
  instance_type = "t2.medium"
  subnet_id     = data.aws_subnet.app_tier_subnet.id

  key_name = "GaSbAllCarisL2Pipeline"
  # iam_instance_profile = "for_dave_cli"
  tags = {
    Name = "ga-sb-${var.env}-caris-l2-pipeline"
  }
  root_block_device {
    volume_type = "gp2"
    volume_size = 30
  }
  lifecycle {
    prevent_destroy = true
  }
}

