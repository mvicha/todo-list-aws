import java.time.*

Date now = new Date()
int timeInSeconds = now.getTime()
if (timeInSeconds < 0) {
  println(timeInSeconds)
  timeInSeconds = (timeInSeconds * -1)
}
def CUSTOM_NET_NAME = "aws-${timeInSeconds}"

node {
  stage('Clean') {
    deleteDir()
    sh 'printenv'
  }

  stage('Debug') {
    sh 'pwd'
    sh 'ls -la'
  }

  stage('Checkout') {
    echo 'Checkout SCM'
    checkout scm
  }

  stage('Pull docker images') {
    sh "docker image pull 750489264097.dkr.ecr.us-east-1.amazonaws.com/mvicha-ecr-jenkins:latest"
    sh "docker image pull amazon/dynamodb-local:latest"
  }

  stage('Prepare docker env') {
    echo "Create network ${CUSTOM_NET_NAME}"
    sh "docker network create ${CUSTOM_NET_NAME}"
  }

  stage('Start DynamoDB / Test environment') {
    sh "docker container run --name dynamo-env-${timeInSeconds} --network ${CUSTOM_NET_NAME} -d --rm -v /var/run/docker.sock:/var/run/docker.sock -v \${HOME}/.aws/credentials:/root/.aws/credentials -v \${HOME}/.aws/config:/root/.aws/config -v \${HOME}/.docker/config.json:/root/.docker/config.json -v \${PWD}:/opt/todo-list-serverless 750489264097.dkr.ecr.us-east-1.amazonaws.com/mvicha-ecr-dynamo:latest /opt/todo-list-serverless/test"
  }

  stage('Run tests 1/2 - Static tests') {
    sh "docker container exec dynamo-env-${timeInSeconds} /opt/todo-list-serverless/test/run_tests.sh"
  }

  stage('Run tests 2/2 - unittest') {
    sh "docker container exec dynamo-env-${timeInSeconds} /opt/todo-list-serverless/test/run_unittest.sh"
  }

  stage('Package application') {
    sh "docker container exec dynamo-env-${timeInSeconds} sam package -t /opt/todo-list-serverless/template.yaml --debug --s3-bucket es-unir-staging-s3-95853-artifacts"
  }

  stage('Remove local DynamoDB container') {
    sh "docker container rm -f dynamo-env-${timeInSeconds}"
  }

  stage('Remove docker network') {
    sh "docker network rm ${CUSTOM_NET_NAME}"
  }

}
