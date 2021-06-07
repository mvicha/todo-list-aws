#create a new instance of the latest Ubuntu 20.04 on an
# t3.micro node with an AWS Tag naming it "HelloWorld"
data "aws_caller_identity" "current" {}

data "template_file" "setup" {
  template = file("${path.module}/templates/setup.tpl")

  vars = {
    jenkinsHome           = var.jenkinsHome
    jenkinsVolume         = var.jenkinsVolume
    jenkinsHttp           = var.jenkinsHttp
    jenkinsHttps          = var.jenkinsHttps
    jenkinsImage          = var.jenkinsImage
    jenkinsUser           = var.jenkinsUser
    jenkinsPassword       = var.jenkinsPassword
    ssh_user              = var.ssh_user
    accountId             = data.aws_caller_identity.current.account_id
    repoUnirCredentials   = var.repo_unir_credentials
    repoTodoListPipelines = var.repo_todo_list_pipelines
    pythonEcr             = local.python_ecr
    pythonImage           = local.python_env_image
    pythonRepo            = local.aws_python_env_repo
    todoRepo              = local.aws_todo_list_repo
    devBucket             = aws_s3_bucket.s3_bucket_development.id
    stgBucket             = aws_s3_bucket.s3_bucket_staging.id
    prodBucket            = aws_s3_bucket.s3_bucket_production.id
  }
}

data "template_cloudinit_config" "cloud_init_config" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "setup.cfg"
    content_type = "text/cloud-config"
    #content_type = "text/x-shellscript"
    content      = data.template_file.setup.rendered
  }
}

resource "aws_instance" "jenkins" {
  ami               = var.ami_id # us-east-1
  instance_type     = var.instance_type
  key_name          = module.key_pair.key_pair_key_name
  availability_zone = "us-east-1a"

  security_groups = [aws_security_group.allow_all.name]
  tags = {
    "Name" = "es-unir-ec2-production-jenkins-server-${random_integer.server.result}"
  }

  user_data_base64 = data.template_cloudinit_config.cloud_init_config.rendered
}

resource "random_integer" "server" {
  min = 10000
  max = 99999
  keepers = {
    # Generate a new id each time we switch to a new AMI id
    ami_id = var.ami_id
  }
}

resource "null_resource" "wait_for_cloud_init" {
  triggers = {
    public_ip = aws_instance.jenkins.public_ip
  }

  connection {
    type        = "ssh"
    host        = aws_instance.jenkins.public_ip
    user        = var.ssh_user
    private_key = tls_private_key.this.private_key_pem
    port        = var.ssh_port
    agent       = true
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f ${var.jenkinsVolume}/custom_setup ]; do sleep 10; done"
    ]
  }
}
