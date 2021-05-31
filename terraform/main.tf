#create a new instance of the latest Ubuntu 20.04 on an
# t3.micro node with an AWS Tag naming it "HelloWorld"
data "aws_caller_identity" "current" {}

resource "aws_instance" "jenkins" {
  ami           = var.ami_id # us-east-1
  instance_type = var.instance_type
  key_name      = module.key_pair.key_pair_key_name

  security_groups = [aws_security_group.allow_all.name]
  tags = {
    "Name" = "es-unir-ec2-production-jenkins-server-${random_integer.server.result}"
  }

  user_data = <<EOF
    #!/bin/bash

    # Setup ENABLE-UNIR-CREDENTIALS
    # Este cambio permite el login a dkr
    if [[ -d "/var/lib/jenkins/jobs/ENABLE-UNIR-CREDENTIALS" ]]; then
      echo "Eliminando antiguo JOB /var/lib/jenkins/job/ENABLE-UNIR-CREDENTIALS"
      sudo rm -rf /var/lib/jenkins/jobs/ENABLE-UNIR-CREDENTIALS
    fi
    sudo -u jenkins git clone https://github.com/mvicha/ENABLE_UNIR_CREDENTIALS.git /var/lib/jenkins/jobs/ENABLE-UNIR-CREDENTIALS
    sudo sed -i "s/AWSAccountId/${data.aws_caller_identity.current.account_id}/g" /var/lib/jenkins/jobs/ENABLE-UNIR-CREDENTIALS/config.xml
    sudo chown -R jenkins:jenkins /var/lib/jenkins/jobs/ENABLE-UNIR-CREDENTIALS
    sudo chmod 755 /var/lib/jenkins/jobs/ENABLE-UNIR-CREDENTIALS

    sudo -u jenkins git clone https://github.com/mvicha/TODO-LIST.git -b feature-gitplugin /tmp/TODO-LIST

    if [[ -d "/var/lib/jenkins/jobs/Python-Env" ]]; then
      echo "Eliminando antiguo JOB /var/lib/jenkins/job/Python-Env"
      sudo -u jenkins rm -rf /var/lib/jenkins/jobs/Python-Env
    fi
    sudo -u jenkins sed -i 's@dkr_python_env_url@${aws_ecr_repository.ecr_python_env.repository_url}@g' /tmp/TODO-LIST/Python-Env/config.xml
    sudo -u jenkins sed -i 's@codecommit_python_env_url@${aws_codecommit_repository.python_env.clone_url_ssh}@g' /tmp/TODO-LIST/Python-Env/config.xml
    sudo -u jenkins mv /tmp/TODO-LIST/Python-Env /var/lib/jenkins/jobs/Python-Env

    if [[ -d "/var/lib/jenkins/jobs/PIPELINE-FULL-STAGING" ]]; then
      sudo rm -rf /var/lib/jenkins/jobs/PIPELINE-FULL-STAGING
    fi
    sudo -u jenkins sed -i 's@codecommit_todo_list_repo@${aws_codecommit_repository.todo_list.clone_url_ssh}@g' /tmp/TODO-LIST/PIPELINE-FULL-STAGING/config.xml
    sudo -u jenkins sed -i 's@dkr_python_env_url@${aws_ecr_repository.ecr_python_env.repository_url}@g' /tmp/TODO-LIST/PIPELINE-FULL-STAGING/config.xml
    sudo -u jenkins sed -i 's@staging_bucket_name@${aws_s3_bucket.s3_bucket_staging.id}@g' /tmp/TODO-LIST/PIPELINE-FULL-STAGING/config.xml
    sudo -u jenkins sed -i 's@production_bucket_name@${aws_s3_bucket.s3_bucket_production.id}@g' /tmp/TODO-LIST/PIPELINE-FULL-STAGING/config.xml
    sudo -u jenkins mv /tmp/TODO-LIST/PIPELINE-FULL-STAGING /var/lib/jenkins/jobs/PIPELINE-FULL-STAGING

    if [[ -d "/var/lib/jenkins/jobs/PIPELINE-FULL-PRODUCTION" ]]; then
      echo "Eliminando antiguo JOB /var/lib/jenkins/job/PIPELINE-FULL-STAGING"
      sudo rm -rf /var/lib/jenkins/jobs/PIPELINE-FULL-PRODUCTION
    fi
    sudo -u jenkins sed -i 's@codecommit_todo_list_repo@${aws_codecommit_repository.todo_list.clone_url_ssh}@g' /tmp/TODO-LIST/PIPELINE-FULL-PRODUCTION/config.xml
    sudo -u jenkins sed -i 's@dkr_python_env_url@${aws_ecr_repository.ecr_python_env.repository_url}@g' /tmp/TODO-LIST/PIPELINE-FULL-PRODUCTION/config.xml
    sudo -u jenkins sed -i 's@staging_bucket_name@${aws_s3_bucket.s3_bucket_staging.id}@g' /tmp/TODO-LIST/PIPELINE-FULL-PRODUCTION/config.xml
    sudo -u jenkins sed -i 's@production_bucket_name@${aws_s3_bucket.s3_bucket_production.id}@g' /tmp/TODO-LIST/PIPELINE-FULL-PRODUCTION/config.xml
    sudo -u jenkins mv /tmp/TODO-LIST/PIPELINE-FULL-PRODUCTION /var/lib/jenkins/jobs/PIPELINE-FULL-PRODUCTION

    if [[ -d "/var/lib/jenkins/jobs/PIPELINE-FULL-CD" ]]; then
      echo "Eliminando antiguo JOB /var/lib/jenkins/job/PIPELINE-FULL-CD"
      sudo rm -rf /var/lib/jenkins/jobs/PIPELINE-FULL-CD
    fi
    sudo -u jenkins sed -i 's@codecommit_todo_list_repo@${aws_codecommit_repository.todo_list.clone_url_ssh}@g' /tmp/TODO-LIST/PIPELINE-FULL-CD/config.xml
    sudo -u jenkins sed -i 's@dkr_python_env_url@${aws_ecr_repository.ecr_python_env.repository_url}@g' /tmp/TODO-LIST/PIPELINE-FULL-CD/config.xml
    sudo -u jenkins mv /tmp/TODO-LIST/PIPELINE-FULL-CD /var/lib/jenkins/jobs/PIPELINE-FULL-CD

    sudo systemctl restart jenkins
  EOF
}

resource "random_integer" "server" {
  min = 10000
  max = 99999
  keepers = {
    # Generate a new id each time we switch to a new AMI id
    ami_id = var.ami_id
  }
}

