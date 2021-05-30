resource "aws_codecommit_repository" "python_env" {
  repository_name = var.codecommit_python_env
  description     = "Repositorio para guardar el entorno de desarrollo"
}

resource "aws_codecommit_repository" "todo_list" {
  repository_name = var.codecommit_todo_list
  description     = "Repositorio para guardar el entorno de la app"
}
