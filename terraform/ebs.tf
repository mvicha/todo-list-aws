resource "aws_ebs_volume" "docker" {
  availability_zone = "us-east-1a"
  size              = 20
}

resource "aws_volume_attachment" "docker_att" {
  device_name = "/dev/xvdc"
  volume_id   = aws_ebs_volume.docker.id
  instance_id = aws_instance.jenkins.id
}

resource "aws_ebs_volume" "jenkins" {
  availability_zone = "us-east-1a"
  size              = 5
}

resource "aws_volume_attachment" "jenkins_att" {
  device_name = "/dev/xvdd"
  volume_id   = aws_ebs_volume.jenkins.id
  instance_id = aws_instance.jenkins.id
}
