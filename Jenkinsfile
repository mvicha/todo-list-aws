import java.time.*

Date now = new Date()
int timeInSeconds = now.getTime()
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

  stage('Run tests 1/2 - Static tests') {
    echo 'Run tests'
    sh "docker container run --network ${CUSTOM_NET_NAME} --rm -v /var/run/docker.sock:/var/run/docker.sock -v \${HOME}/.aws/credentials:/root/.aws/credentials -v \${HOME}/.aws/config:/root/.aws/config -v \${HOME}/.docker/config.json:/root/.docker/config.json -v \${PWD}:/opt/todo-list-serverless 750489264097.dkr.ecr.us-east-1.amazonaws.com/mvicha-ecr-jenkins:latest /opt/todo-list-serverless/test/run_tests.sh"
  }

  stage('Run local DynamoDB for testing') {
    echo 'Run local dynamodb'
    sh "docker container run -d --network ${CUSTOM_NET_NAME} --name dynamo-${timeInSeconds} --rm amazon/dynamodb-local:latest"
  }

  stage('Run tests 2/2 - unittest') {
    sh "docker container run --network ${CUSTOM_NET_NAME} --link dynamo-${timeInSeconds}:dynamo --rm -v /var/run/docker.sock:/var/run/docker.sock -v \${HOME}/.aws/credentials:/root/.aws/credentials -v \${HOME}/.aws/config:/root/.aws/config -v \${HOME}/.docker/config.json:/root/.docker/config.json -v \${PWD}:/opt/todo-list-serverless 750489264097.dkr.ecr.us-east-1.amazonaws.com/mvicha-ecr-jenkins:latest /opt/todo-list-serverless/test/run_unittest.sh"
  }

  stage('Remove local DynamoDB container') {
    sh "docker container rm -f dynamo-${timeInSeconds}"
  }

  stage('Remove docker network') {
    sh "docker network rm ${CUSTOM_NET_NAME}"
  }
}
