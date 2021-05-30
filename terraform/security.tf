resource "aws_default_security_group" "default" {
  vpc_id = aws_default_vpc.default.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_all" {
  name        = "es-unir-ec2-jenkins-all-traffic-${random_integer.server.result}"
  description = "Allow all inbound traffic"


  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["${chomp(data.http.myip.body)}/32", "${var.myip}/32"]
    security_groups = [aws_default_security_group.default.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_default_vpc.default.id

  tags = {
    Name        = "es-unir-ec2-production-jenkins-server-securityGroup"
    Country     = "es"
    Team        = "unir"
    Environment = "production"
  }
}

data "aws_iam_policy" "CodeCommitFullAccess" {
  arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
}