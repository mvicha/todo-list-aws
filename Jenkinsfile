import java.time.*

Date now = new Date()
Integer timeInSeconds = now.getTime()
if (timeInSeconds < 0) {
  println("Time is lower than 0: " + timeInSeconds.toString())
  timeInSeconds = (timeInSeconds * -1)
  println("Fixed Time is now: " + timeInSeconds.toString())
}

if (GIT_BRANCH == "origin/develop") {
  s3bucket = "es-unir-staging-s3-95853-artifacts"
  doLocal = false
  doTests = true
} else if (GIT_BRANCH == "origin/master") {
  s3bucket = "es-unir-staging-s3-95853-artifacts"
  doLocal = false
  doTests = false
} else {
  doLocal = true
  doTests = true
}


def cleanUp(debugenv) {
  stage('Clean') {
    deleteDir()
    if (debugenv) {
      sh 'printenv'
    }
  }
}

def dockerNetwork(action, timeInSeconds) {
  switch(action) {
    case 'create':
      stage('Create Docker Network') {
        sh "docker network create aws-${timeInSeconds}"
      }
      break;
    case 'remove':
      stage('Remove Docker Network') {
        sh "docker network remove aws-${timeInSeconds}"
      }
      break;
  }
}

def pythonBuildEnv(action, timeInSeconds, doLocal) {
  switch(action) {
    case 'create':
      stage('Create Build Environment') {
        if (doLocal) {
          sh "docker container run --name python-env-${timeInSeconds} --link dynamo-${timeInSeconds}:dynamodb --network aws-${timeInSeconds} -di -v /var/run/docker.sock:/var/run/docker.sock -v \${HOME}/.aws:/home/builduser/.aws -v \${PWD}:\${PWD} 750489264097.dkr.ecr.us-east-1.amazonaws.com/mvicha-ecr-python-env:latest"
        } else {
          sh "docker container run --name python-env-${timeInSeconds} --network aws-${timeInSeconds} -di -v /var/run/docker.sock:/var/run/docker.sock -v \${HOME}/.aws:/home/builduser/.aws -v \${PWD}:\${PWD} 750489264097.dkr.ecr.us-east-1.amazonaws.com/mvicha-ecr-python-env:latest"
        }
      }
      break;
    case 'remove':
      stage('Remove Build Environment') {
        sh "docker container rm -f python-env-${timeInSeconds}"
      }
      break;
  }
}

def localDynamo(action, timeInSeconds, doTests) {
  if (doTests) {
    switch(action) {
      case 'create':
        stage('Create local dynamodb') {
          sh "docker container run -d --network aws-${timeInSeconds} --name dynamo-${timeInSeconds} --rm amazon/dynamodb-local"
          sh "docker container run --rm --network aws-${timeInSeconds} --link dynamo-${timeInSeconds}:dynamodb -v ~/.aws:/root/.aws -v ${PWD}/table.json:/tmp/table.json amazon/aws-cli dynamodb create-table --cli-input-json file:///tmp/table.json --endpoint-url http://dynamodb:8000"
        }
        break;
      case 'remove':
        stage('Remove local dynamodb') {
          sh "docker container rm -f dynamo-${timeInSeconds}"
        }
        break;
    }
  }
}

def testApp(timeInSeconds, doLocal, testCase) {
  switch(testCase) {
    case 'static':
      if (doTests) {
        stage('Run tests 1/2 - Static tests') {
          sh "docker container exec python-env-${timeInSeconds} /opt/todo-list-aws/test/run_tests.sh"
        }
      }
      break;
    case 'unittest':
      if (doTests) {
        stage('Run tests 2/2 - unittest') {
          sh "docker container exec python-env-${timeInSeconds} /opt/todo-list-aws/test/run_unittest.sh"
        }
      }
      break;
    case 'integration':
      stage('Run integration tests') {
        if (doLocal) {
          sh "docker container exec python-env-${timeInSeconds} /opt/todo-list-aws/test/run_final.sh true"
        } else {
          sh "docker container exec python-env-${timeInSeconds} /opt/todo-list-aws/test/run_final.sh"
        }
      }
  }
}

def linkDirectory(source, destination) {
  sh "docker container exec -u root python-env-${timeInSeconds} ln -sf ${source} ${destination}"
}

def startLocalApi(timeInSeconds, doTests) {
  if (doTests) {
    stage("Start sam local-api") {
      sh "docker container exec -d -w \${PWD} python-env-${timeInSeconds} /home/builduser/.local/bin/sam local start-api -t /opt/todo-list-aws/template.yaml --region us-east-1 --port 8080 --debug --docker-network aws-${timeInSeconds}"
    }
  }
}

def deployApp(timeInSeconds, doLocal) {
  if (!doLocal) {
    stage('Deploy application') {
      sh "docker container exec python-env-${timeInSeconds} /home/builduser/.local/bin/sam deploy -t /opt/todo-list-aws/template.yaml --debug --force-upload --stack-name todo-list-aws-staging --debug --s3-bucket ${s3bucket} --capabilities CAPABILITY_IAM"
    }
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
    sh "docker image pull 750489264097.dkr.ecr.us-east-1.amazonaws.com/mvicha-ecr-python-env:latest"
    sh "docker image pull amazon/dynamodb-local"
  }

  try {
    dockerNetwork('create', timeInSeconds)
    try {
      localDynamo('create', timeInSeconds, doLocal)
      try {
        pythonBuildEnv('create', timeInSeconds, doLocal)
        try {
          linkDirectory(WORKSPACE, "/opt/todo-list-aws")
          testApp(timeInSeconds, doLocal, 'static')
          testApp(timeInSeconds, doLocal, 'unittest')
          startLocalApi(timeInSeconds, doTests)
          deployApp(timeInSeconds, doLocal)
          testApp(timeInSeconds, doLocal, 'integration')
        } catch(r) {
          printFailure(r)
        } finally {
          pythonBuildEnv('remove', timeInSeconds, doLocal)
        }
      } catch(ld) {
        printFailure(ld)
      } finally {
        localDynamo('remove', timeInSeconds, doTests)
      }
    } catch(be) {
      printFailure(be)
    } finally {
      dockerNetwork('remove', timeInSeconds)
    }
  } catch(dn) {
    printFailure(dn)
  }

  cleanUp(false)
}
