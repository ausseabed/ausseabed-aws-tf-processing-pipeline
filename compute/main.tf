#----compute/main.tf


data "aws_ecs_cluster" "main" {
  cluster_name = "ga_sb_${var.env}_ecs_cluster"

}
data "aws_caller_identity" "current" {}

resource "aws_ecs_task_definition" "caris-version" {
  family       = "caris-version"
  network_mode = "awsvpc"
  requires_compatibilities = [
  "FARGATE"]
  cpu                = var.fargate_cpu
  memory             = var.fargate_memory
  execution_role_arn = var.ecs_task_execution_role_arn
  task_role_arn      = var.ecs_task_execution_role_arn

  # 52.62.84.70 is IP address of CARIS manual box in *PROD* account
  container_definitions = <<DEFINITION
[
  {
    "logConfiguration": {
        "logDriver": "awslogs",
        "secretOptions": null,
        "options": {
          "awslogs-group": "/ecs/ga_sb_${var.env}_caris-version",
          "awslogs-region": "ap-southeast-2",
          "awslogs-stream-prefix": "ecs"
        }
      },
    "command": ["52.62.84.70",
        "\"C:\\Program Files\\CARIS\\HIPS and SIPS\\11.2\\bin\\carisbatch\" --version",
        "arnab",
        "caris_rsa_pkey_string"],
    "secrets": [
        {
          "valueFrom": "arn:aws:secretsmanager:ap-southeast-2:288871573946:secret:caris_batch_secret-OMZKQN",
          "name": "caris_rsa_pkey_string"
        }
      ],
    "cpu": ${var.fargate_cpu},
    "image": "${var.caris_caller_image}",
    "memory": ${var.fargate_memory},
    "name": "app",
    "networkMode": "awsvpc",
    "portMappings": []
  }
]
DEFINITION
}


resource "aws_ecs_task_definition" "startstopec2" {
  family       = "startstopec2"
  network_mode = "awsvpc"
  requires_compatibilities = [
  "FARGATE"]
  cpu                = var.fargate_cpu
  memory             = var.fargate_memory
  execution_role_arn = var.ecs_task_execution_role_arn
  task_role_arn      = var.ecs_task_execution_role_arn

  container_definitions = <<DEFINITION
[
  { "logConfiguration": {
        "logDriver": "awslogs",
        "secretOptions": null,
        "options": {
          "awslogs-group": "/ecs/ga_sb_${var.env}_startstopec2",
          "awslogs-region": "ap-southeast-2",
          "awslogs-stream-prefix": "ecs"
        }
      },
    "cpu": ${var.fargate_cpu},
    "image": "${var.startstopec2_image}",
    "memory": ${var.fargate_memory},
    "name": "app",
    "networkMode": "awsvpc",
    "portMappings": []
  }
]
DEFINITION
}




resource "aws_ecs_task_definition" "gdalbigtiff" {
  family       = "gdalbigtiff"
  network_mode = "awsvpc"
  requires_compatibilities = [
  "FARGATE"]
  cpu                = var.fargate_cpu
  memory             = var.fargate_memory
  execution_role_arn = var.ecs_task_execution_role_arn
  task_role_arn      = var.ecs_task_execution_role_arn

  container_definitions = <<DEFINITION
[
  { "logConfiguration": {
        "logDriver": "awslogs",
        "secretOptions": null,
        "options": {
          "awslogs-group": "/ecs/ga_sb_${var.env}_containers",
          "awslogs-region": "ap-southeast-2",
          "awslogs-stream-prefix": "gdal"
        }
      },
    "cpu": ${var.fargate_cpu},
    "image": "${var.gdal_image}",
    "memory": ${var.fargate_memory},
    "name": "app",
    "networkMode": "awsvpc",
    "environment": [
      {
        "name": "S3_ACCOUNT_CANONICAL_ID",
        "value": "${var.prod_data_s3_account_canonical_id}"
      }
    ],
    "portMappings": [],
    "mountPoints": [
      {
        "sourceVolume": "${var.gdal_efs.creation_token}",
        "containerPath": "/mnt/efs",
        "readOnly" : false
      }
    ],
    "workingDirectory": "/mnt/efs"
  }
]
DEFINITION
  volume {
    name = var.gdal_efs.creation_token
    efs_volume_configuration {
      file_system_id = var.gdal_efs.id
      root_directory = "/"
      # transit_encryption = "ENABLED"
      # transit_encryption_port = 2999
      # authorization_config {
      #   access_point_id = aws_efs_access_point.test.id // TODO
      #   iam             = "ENABLED"
      # }
    }
  }
}

resource "aws_ecs_task_definition" "gdal" {
  family       = "gdal"
  network_mode = "awsvpc"
  requires_compatibilities = [
  "FARGATE"]
  cpu                = var.fargate_cpu
  memory             = var.fargate_memory
  execution_role_arn = var.ecs_task_execution_role_arn
  task_role_arn      = var.ecs_task_execution_role_arn

  container_definitions = <<DEFINITION
[
  { "logConfiguration": {
        "logDriver": "awslogs",
        "secretOptions": null,
        "options": {
          "awslogs-group": "/ecs/ga_sb_${var.env}_containers",
          "awslogs-region": "ap-southeast-2",
          "awslogs-stream-prefix": "gdal"
        }
      },
    "cpu": ${var.fargate_cpu},
    "image": "${var.gdal_image}",
    "memory": ${var.fargate_memory},
    "name": "app",
    "networkMode": "awsvpc",
    "environment": [
      {
        "name": "S3_ACCOUNT_CANONICAL_ID",
        "value": "${var.prod_data_s3_account_canonical_id}"
      }
    ],
    "portMappings": []
  }
]
DEFINITION
}

resource "aws_ecs_task_definition" "mbsystem" {
  family       = "mbsystem"
  network_mode = "awsvpc"
  requires_compatibilities = [
  "FARGATE"]
  cpu                = var.fargate_cpu
  memory             = var.fargate_memory
  execution_role_arn = var.ecs_task_execution_role_arn
  task_role_arn      = var.ecs_task_execution_role_arn

  container_definitions = <<DEFINITION
[
  { "logConfiguration": {
        "logDriver": "awslogs",
        "secretOptions": null,
        "options": {
          "awslogs-group": "/ecs/ga_sb_${var.env}_containers",
          "awslogs-region": "ap-southeast-2",
          "awslogs-stream-prefix": "mbsystem"
        }
      },
    "cpu": ${var.fargate_cpu},
    "image": "${var.mbsystem_image}",
    "memory": ${var.fargate_memory},
    "name": "app",
    "networkMode": "awsvpc",
    "portMappings": []
  }
]
DEFINITION
}

resource "aws_ecs_task_definition" "pdal" {
  family       = "pdal"
  network_mode = "awsvpc"
  requires_compatibilities = [
  "FARGATE"]
  cpu                = var.fargate_cpu
  memory             = var.fargate_memory
  execution_role_arn = var.ecs_task_execution_role_arn
  task_role_arn      = var.ecs_task_execution_role_arn

  container_definitions = <<DEFINITION
[
  { "logConfiguration": {
        "logDriver": "awslogs",
        "secretOptions": null,
        "options": {
          "awslogs-group": "/ecs/ga_sb_${var.env}_containers",
          "awslogs-region": "ap-southeast-2",
          "awslogs-stream-prefix": "pdal"
        }
      },
    "cpu": ${var.fargate_cpu},
    "image": "${var.pdal_image}",
    "memory": ${var.fargate_memory},
    "name": "pdal",
    "networkMode": "awsvpc",
    "portMappings": []
  }
]
DEFINITION
}
