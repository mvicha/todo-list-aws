variable "ami_id" {
  default = "ami-0c2fc02255044bf94"
}

variable "myip" {
  description = "A continuación indicar la IP desde donde se va a conectar al servidor web y la instancia ec2. Revisar en https://www.cualesmiip.com/"
}

variable "instance_type" {
  description = "Tipo de instancia a levantar en AWS. Por defecto es t2.micro. Si se quedase corta, se podría ampliar a t2.small o t2.medium"
  default     = "t2.small"
}

variable "ecr_name" {
  description = "Nombre del ECR que crearemos para guardar las imágenes de Docker para Jenkins"
  default     = "mvicha-ecr-jenkins"
}

variable "ecr_dynamo_name" {
  description = "Nombre del ECR que crearemos para guardar las imágenes Docker de Dynamo con entorno de Python y AWS para Jenkins"
  default     = "mvicha-ecr-dynamo"
}

variable "ecr_python_env_name" {
  description = "Nombre del ECR que crearemos para guardar las imágenes Docker de un entorno de Python y AWS para Jenkins"
  default     = "mvicha-ecr-python-env"
}
