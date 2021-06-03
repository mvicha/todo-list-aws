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
  default     = "mvicha-ecr-python-env-tf"
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
  default     = "git@github.com:mvicha/ENABLE_UNIR_CREDENTIALS.git"
}

variable "create_repositories" {
  description = "Crear repositorios python-env y todo-list-aws o utilizar repositorios existentes"
  default     = true
}

variable "python_env_repo" {
  description = "Repositorio existente de python-env"
  default     = "ssh://git-codecommit.us-east-1.amazonaws.com/v1/repos/python-env"
}

variable "todo_list_repo" {
  description = "Repositorio existente de todo-list-aws"
  default     = "ssh://git-codecommit.us-east-1.amazonaws.com/v1/repos/todo-list-aws"
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
