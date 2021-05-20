import java.time.*

Date now = new Date()
Integer timeInSeconds = now.getTime()
if (timeInSeconds < 0) {
  println("Time is lower than 0: " + timeInSeconds.toString())
  timeInSeconds = (timeInSeconds * -1)
  println("Fixed Time is now: " + timeInSeconds.toString())
}


def cleanUp(debugenv) {
  stage('Clean') {
    deleteDir()
    if (debugenv) {
      sh 'printenv'
    }
  }
}


def testAndDeploy(timeInSeconds) {
  stage('Run tests 1/2 - Static tests') {
    sh "docker container exec dynamo-env-${timeInSeconds} /opt/todo-list-aws/test/run_tests.sh"
  }

  stage('Run tests 2/2 - unittest') {
    sh "docker container exec dynamo-env-${timeInSeconds} /opt/todo-list-aws/test/run_unittest.sh"
  }

  stage('Deploy application') {
    sh "docker container exec dynamo-env-${timeInSeconds} /home/dynamodblocal/.local/bin/sam deploy -t /opt/todo-list-aws/template.yaml --debug --force-upload --stack-name todo-list-aws-staging --debug --s3-bucket es-unir-staging-s3-95853-artifacts --capabilities CAPABILITY_IAM"
  }

  stage('Run final testing) {
    sh "docker container exec dynamo-env-${timeInSeconds} /opt/todo-list-aws/test/run_final.sh"
  }
}


def printFailure(e) {
  println "Failed because of $e"
}


node {
  cleanUp(true)

  stage('Checkout') {
    echo 'Checkout SCM'
    checkout scm
  }

  stage('Pull docker images') {
    sh "docker image pull 750489264097.dkr.ecr.us-east-1.amazonaws.com/mvicha-ecr-dynamo:latest"
  }

  stage('Create deploy container') {
    sh "docker container run --name dynamo-env-${timeInSeconds} -d -v /var/run/docker.sock:/var/run/docker.sock -v \${HOME}/.aws/credentials:/home/dynamodblocal/.aws/credentials -v \${HOME}/.aws/config:/home/dynamodblocal/.aws/config -v \${HOME}/.docker/config.json:/home/dynamodblocal/.docker/config.json -v \${PWD}:/opt/todo-list-aws 750489264097.dkr.ecr.us-east-1.amazonaws.com/mvicha-ecr-dynamo:latest"
  }

  try {
    testAndDeploy(timeInSeconds)
  } catch(e) {
    printFailure(e)
  } finally {
    stage('Remove deploy container') {
      sh "docker container rm -f dynamo-env-${timeInSeconds}"
    }

    cleanUp(false)
  }
}
