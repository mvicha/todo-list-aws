def cloneGit(gitRepo, branchName) {
  stage("Clone ${branchName} Repo") {
    // Limpiamos el entorno antes de comenzar
    deleteDir()
    git branch: branchName,
      credentialsId: 'codecommit',
      url: gitRepo
  }
}

def configGit(gitUsername, gitEmail) {
  stage('Config git globals') {
    sh("""
      git config user.name '${gitUsername}'
      git config user.email '${gitEmail}'
    """)
  }
}

def buildJob(jobName) {
  stage("Build ${jobName}") {
    def job = build job: jobName
  }
}
def mergeGit(origin, dest) {
  stage("Merge ${origin} into ${dest}") {
    sh("""
      git merge origin/${origin}
      git branch --set-upstream-to=origin/${dest} ${dest}
    """)
  }
}
def pushGit(origin) {
  stage("Push ${origin} merged changes") {
    withCredentials([sshUserPrivateKey(credentialsId: 'codecommit', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USERNAME')]) {
      withEnv(["GIT_SSH_COMMAND=ssh -o StrictHostKeyChecking=no -o User=${SSH_USERNAME} -i ${SSH_KEY}"]) {
        sh "git push origin ${origin}"
      }
    }
  }
}

node {
  /*
    Definimos la URL del repositorio de codecommit que luego utilizaremos
  */
  String gitRepo = "ssh://git-codecommit.us-east-1.amazonaws.com/v1/repos/todo-list-aws"

  try {
    /*
      Clonamos dev para configurar
    */
    cloneGit(gitRepo, 'develop')

    /*
      Configuramos git para que utilice un nombre de usuario y un email
    */
    configGit('Jenkins Pipeline', 'jenkins@pipeline.com')

    /*
      Comenzamos la construcción del pipeline de Dev
    */
    buildJob('Todo-List-Dev-Pipeline')

    /*
      Habiendo finalizado Dev correctamente clonamos, mergeamos y pusheamos a staging
    */
    // Clonamos
    cloneGit(gitRepo, 'staging')
    // Mergeamos
    mergeGit('develop', 'staging')
    // Pusheamos
    pushGit('staging')

    /*
      Habiendo mergeado correctamente comenzamos con la construcción del pipeline de staging
    */
    buildJob('Todo-List-Staging-Pipeline')

    /*
        Habiendo finalizado Staging correctamente clonamos, mergeamos y pusheamos a producción
    */
    // Clonamos
    cloneGit(gitRepo, 'master')
    // Mergeamos
    mergeGit('staging', 'master')
    // Pusheamos
    pushGit('master')

    /*
      Habiendo mergeado correctamente comenzamos con la construcción del pipeline de producción
    */
    buildJob('Todo-List-Production-Pipeline')
  } catch(e) {
    println "Failed because of $e"
    currentBuid.result = "FAILURE"
  } finally {
    /*
      Limpiamos el entorno al finalizar
    */
    stage('Cleanup') {
      deleteDir()
    }
  }
}

