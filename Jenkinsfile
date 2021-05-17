pipeline {
  agent any

  parameters {
    string(name: 'GIT_BRANCH', defaultValue: '', description: 'Git branch to use')
    //string(name: 'GIT_CREDENTIALS_ID', defaultValue: '', description: 'Jenkins ID for CodeCommit Git credentials')
    //string(name: 'GIT_URL', defaultValue: '', description: 'Git URL to connect')
  }

  stages {
    stage('Clean') {
      deleteDir()
      sh 'printenv'
    }
  
    /**stage('Checkout') {
      git branch: ${GIT_BRANCH},
      credentialsId: ${GIT_CREDENTIALS_ID},
      url: ${GIT_URL}
    }**/
  
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

