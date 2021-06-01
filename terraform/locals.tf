locals {
  aws_python_env_repo = (create_repository ? aws_codecommit_repository.python_env.clone_url_ssh : var.python_env_repo)
  aws_todo_list_repo = (create_repository ? aws_codecommit_repository.todo_list.clone_url_ssh : var.todo_list_repo)
}
