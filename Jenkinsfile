pipeline {
  agent any

  parameters {
    string(name: 'GIT_BRANCH', defaultValue: '', description: 'Git branch to use')
  }

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

    stage('New Debug') {
      steps {
        sh 'pwd'
        sh 'ls -la'
      }
    }
  }
}

