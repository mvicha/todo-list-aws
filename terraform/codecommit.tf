resource "aws_codecommit_repository" "python_env" {
  count = var.create_repositories ? 1 : 0
  repository_name = var.codecommit_python_env
  description     = "Repositorio para guardar el entorno de desarrollo"
}

resource "aws_codecommit_repository" "todo_list" {
  count = var.create_repositories ? 1 : 0
  repository_name = var.codecommit_todo_list
  description     = "Repositorio para guardar el entorno de la app"
}
