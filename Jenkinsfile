pipeline {
  agent any

  /* parameters {
    string(name: 'GIT_BRANCH', defaultValue: '', description: 'Git branch to use')
  } */

  stages {
    stage('Clean') {
      steps {
        deleteDir()
        sh 'printenv'
      }
    }
  
    stage('Debug') {
      steps {
        sh 'pwd'
        sh 'ls -la'
      }
    }

    stage('Checkout') {
      steps {
        echo 'Checkout SCM'
        checkout scm
      }
    }

    stage('Create Docker container') {
      steps {
        echo 'Run static code test. Expect quality B or better'
        sh 'docker container run --rm -v /var/run/docker.sock:/var/run/docker.sock -v ${HOME}/.aws/credentials:/root/.aws/credentials -v ${HOME}/.aws/config:/root/.aws/config -v ${HOME}/.docker/config.json:/root/.docker/config.json -v ${PWD}:/opt/todo-list-serverless 750489264097.dkr.ecr.us-east-1.amazonaws.com/mvicha-ecr-jenkins:latest radon cc /opt/todo-list-serverless/ -a -nc'
      }
    }
  }
}

