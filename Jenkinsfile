pipeline {
  agent any
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

