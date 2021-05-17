pipeline {
  agent any
  parameters {
    string(name: 'GIT_BRANCH', defaultValue: 'develop', description: 'Git branch to clone')
  }
  stages {
    stage('Clean') {
      steps {
        sh 'pwd'
        sh 'ls -la'
        deleteDir()
        sh 'printenv'
        sh 'ls -la'
      }
    }

    stage('Checkout') {
      steps {
        checkout scm
      }
    }
  }
}

