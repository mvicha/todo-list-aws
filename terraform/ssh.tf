resource "tls_private_key" "this" {
  algorithm = "RSA"
}

# Jenkins SSH Key
module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "es-unir-keypair-${random_integer.server.result}"
  public_key = tls_private_key.this.public_key_openssh
}

resource "null_resource" "super_secret" {
  # triggers = {
  #   hash_super_secret = sha256(tls_private_key.this.private_key_pem)
  # }

  triggers = {
    always_run = timestamp()
  }


  provisioner "local-exec" {
    command = "echo $SUPER_SECRET > jenkins_key_pem "
    environment = {
      SUPER_SECRET = tls_private_key.this.private_key_pem
    }
  }
}

resource "null_resource" "create_pem" {
  # triggers = {
  #   hash_super_secret = sha256(tls_private_key.this.private_key_pem)
  # }

  triggers = {
    always_run = timestamp()
  }


  provisioner "local-exec" {
    command = "resources/get-ssh-key.sh jenkins"
  }

  depends_on = [null_resource.super_secret]
}


# CodeCommit SSH Key
resource "tls_private_key" "codecommit" {
  algorithm = "RSA"
}

module "key_pair_cc" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "codecommit-${random_integer.server.result}"
  public_key = tls_private_key.codecommit.public_key_openssh
}

resource "null_resource" "super_secret_cc" {
  # triggers = {
  #   hash_super_secret = sha256(tls_private_key.codecommit.private_key_pem)
  # }

  triggers = {
    always_run = timestamp()
  }


  provisioner "local-exec" {
    command = "echo $SUPER_SECRET > codecommit_key_pem "
    environment = {
      SUPER_SECRET = tls_private_key.codecommit.private_key_pem
    }
  }
}

resource "null_resource" "create_pem_cc" {
  # triggers = {
  #   hash_super_secret = sha256(tls_private_key.codecommit.private_key_pem)
  # }

  triggers = {
    always_run = timestamp()
  }


  provisioner "local-exec" {
    command = "resources/get-ssh-key.sh codecommit"
  }

  depends_on = [null_resource.super_secret_cc]
}
