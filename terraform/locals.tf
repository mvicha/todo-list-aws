locals {
  aws_python_env_repo = var.create_repositories ? aws_codecommit_repository.python_env[0].clone_url_ssh : var.python_env_repo
  aws_todo_list_repo = var.create_repositories ? aws_codecommit_repository.todo_list[0].clone_url_ssh : var.todo_list_repo
}
