resource "aws_ecr_repository" "ecr_python_env" {
  name                 = var.ecr_python_env_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
