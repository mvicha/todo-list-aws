output "key_pair_jenkins" {
  value = tls_private_key.this.private_key_pem
  #sensitive = true
}

output "key_pair_codecommit" {
  value = tls_private_key.codecommit.private_key_pem
  #sensitive = true
}

output "codecommit_key_id" {
  value = aws_iam_user_ssh_key.codecommit.ssh_public_key_id
}

output "s3_bucket_development" {
  value = aws_s3_bucket.s3_bucket_development.id
}

output "s3_bucket_production" {
  value = aws_s3_bucket.s3_bucket_production.id
}

output "s3_bucket_staging" {
  value = aws_s3_bucket.s3_bucket_staging.id
}

output "jenkins_instance_id" {
  value = aws_instance.jenkins.id
}

output "jenkins_instance_security_group_id" {
  value = aws_security_group.allow_all.id
}
output "ssh_connection" {
  value = "ssh -i resources/jenkins/key.pem ${var.ssh_user}@${aws_instance.jenkins.public_ip}"
}
output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:${var.jenkinsHttp}"
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "ecr_python_env_url" {
  value = local.python_ecr
}

output "python_env_repo" {
  value = local.aws_python_env_repo
}

output "todo_list_env_repo" {
  value = local.aws_todo_list_repo
}

output "python_env_image" {
  value = local.python_env_image
}
