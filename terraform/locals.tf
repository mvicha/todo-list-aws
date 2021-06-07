locals {
  aws_python_env_repo = length(var.python_env_repo) == 0 ? aws_codecommit_repository.python_env[0].clone_url_ssh : var.python_env_repo
  aws_todo_list_repo  = length(var.todo_list_repo) == 0 ? aws_codecommit_repository.todo_list[0].clone_url_ssh : var.todo_list_repo
  python_env_image    = length(var.python_env_image) == 0 ? aws_ecr_repository.ecr_python_env.repository_url : var.python_env_image
  python_ecr          = var.create_repositories ? aws_ecr_repository.ecr_python_env.repository_url : ""
}
