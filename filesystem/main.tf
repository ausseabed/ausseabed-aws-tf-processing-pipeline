# Create the File System
resource "aws_efs_file_system" "gdal_temp_efs" {
  creation_token = "ga_sb_${var.env}_efs"
  tags = {
    Name = "ga_sb_${var.env}_efs"
  }
}
# Create the access point with the given user permissions
resource "aws_efs_access_point" "gdal_temp_efs_access_point" {
  file_system_id = aws_efs_file_system.gdal_temp_efs.id
  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory {
    path = "/mnt/efs"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 755
    }
  }
  tags = {
    Name = "ga_sb_${var.env}_efs_gdalbigtif"
  }
}
# Create the mount targets on your private subnets
# we are provisioning in subnet XXX because it is hardcoded in the launch of the container
# to StepFunction
resource "aws_efs_mount_target" "gdal_temp_efs_mount_target" {
  count           = length(var.networking.app_tier_subnets)
  file_system_id  = aws_efs_file_system.gdal_temp_efs.id
  subnet_id       = var.networking.app_tier_subnets[count.index]
  security_groups = [var.networking.pipelines_sg]
}
