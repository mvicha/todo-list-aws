resource "aws_iam_user" "codecommit" {
  name = "codecommit-tf"
  path = "/"
}

resource "aws_iam_user_ssh_key" "codecommit" {
  username    = aws_iam_user.codecommit.name
  encoding    = "SSH"
  public_key  = tls_private_key.codecommit.public_key_openssh
}

resource "aws_iam_user_policy_attachment" "codecommit" {
  user        = aws_iam_user.codecommit.name
  policy_arn  = data.aws_iam_policy.CodeCommitFullAccess.arn
}