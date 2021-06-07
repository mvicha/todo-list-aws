variable "ami_id" {
  #default = "ami-0c2fc02255044bf94"
  default = "ami-0d5eff06f840b45e9"
}

variable "myip" {
  description = "A continuación indicar la IP desde donde se va a conectar al servidor web y la instancia ec2. Revisar en https://www.cualesmiip.com/"
}

variable "instance_type" {
  description = "Tipo de instancia a levantar en AWS. Por defecto es t2.micro. Si se quedase corta, se podría ampliar a t2.small o t2.medium"
  default     = "t2.small"
}

variable "ecr_python_env_name" {
  description = "Nombre del ECR que crearemos para guardar las imágenes Docker de un entorno de Python y AWS para Jenkins"
  default     = "ecr-python-env-tf"
}

variable "codecommit_python_env" {
  description = "Nombre del repositorio para guardar el entorno de desarrollo"
  default     = "python-env-tf"
}

variable "codecommit_todo_list" {
  description = "Nombre del repositorio para guardar los sources de la app"
  default     = "todo-list-aws-tf"
}

variable "repo_unir_credentials" {
  description = "Repositorio que contiene el job de unir"
  default     = "https://github.com/mvicha/ENABLE_UNIR_CREDENTIALS.git"
}

variable "repo_todo_list_pipelines" {
  description = "Repositorio que contiene los pipelines de Jenkins"
  default     = "https://github.com/mvicha/TODO-LIST.git"
}

variable "create_repositories" {
  description = "Crear repositorios python-env y todo-list-aws o utilizar repositorios existentes"
  default     = false
}

variable "python_env_repo" {
  description = "Repositorio existente de python-env"
  default     = "https://github.com/mvicha/python-env.git"
}

variable "python_env_image" {
  description = "Imagen preexistente de Python-Env"
  default     = "mvilla/python-env:latest"
}

variable "todo_list_repo" {
  description = "Repositorio existente de todo-list-aws"
  default     = "https://github.com/mvicha/todo-list-aws.git"
}

variable "jenkinsHome" {
  default = "/var/lib/jenkins"
}

variable "jenkinsVolume" {
  default = "/var/lib/jenkins"
}

variable "ssh_port" {
  default = 22
}

variable "jenkinsHttp" {
  default = 80
}

variable "jenkinsHttps" {
  default = 443
}

variable "jenkinsUser" {
  default = "unir"
}

variable "jenkinsPassword" {
  default = "changeme"
}

variable "ssh_user" {
  default = "ec2-user"
}

variable "jenkinsImage" {
  default = "mvilla/jenkinsawsdocker:latest"
}
