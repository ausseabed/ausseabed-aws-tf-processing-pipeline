
data "aws_subnet" "app_tier_subnet" {
  filter {
    name   = "tag:Name"
    values = ["ga_sb_${var.env}_vpc_app_1"]
  }
}

data "aws_subnet" "web_tier_subnet" {
  filter {
    name   = "tag:Name"
    values = ["ga_sb_${var.env}_vpc_web_1"]
  }
}

# Key should be GaSbAllCarisL2Pipeline
# aws ec2 create-key-pair --key-name GaSbAllCarisL2Pipeline --query 'KeyMaterial'  --output text > GaSbAllCarisL2Pipeline.pem
# in secrets manager
resource "aws_instance" "app_tier_instance" {
  ami           = var.caris_ami
  instance_type = var.env == "prod" ? "t2.medium" : "t2.large"
  subnet_id     = data.aws_subnet.app_tier_subnet.id

  key_name               = "GaSbAllCarisL2Pipeline"
  iam_instance_profile   = var.caris_ec2_iip
  vpc_security_group_ids = [var.caris_sg]

  tags = {
    Name      = "ga-sb-${var.env}-caris-l2-pipeline"
    AgentRole = "pipeline"
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = 30
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name  = "xvdg"
  volume_id    = aws_ebs_volume.caris_pipeline_vol.id
  instance_id  = aws_instance.app_tier_instance.id
  skip_destroy = true
}

resource "aws_ebs_volume" "caris_pipeline_vol" {
  availability_zone = "ap-southeast-2a"
  size              = 1024

  tags = {
    Name = "ga-sb-${var.env}-caris-pipeline-vol"
  }
}
