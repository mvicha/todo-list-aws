import java.time.*

/*
  Generamos un valor timeInSeconds para darles un nombre único a los recursos
*/
Date now = new Date()
Integer timeInSeconds = now.getTime()
if (timeInSeconds < 0) {
  println("Time is lower than 0: " + timeInSeconds.toString())
  timeInSeconds = (timeInSeconds * -1)
  println("Fixed Time is now: " + timeInSeconds.toString())
}


/*
  Seteamos la variable GIT_BRANCH en caso de que no exista
*/
if (!env.GIT_BRANCH) {
    echo "NULL VALUE FOR GIT_BRANCH"
    GIT_BRANCH = scm.branches[0].name
}


/*
  Definir valores en base al branch:
    - s3bucket: Bucket que se utiliza para guardar los archivos de SAM
    - doLocal: Utilizado para validar ejecución en entorno local
    - doTests: Utilizado para validar realización de pruebas
    - stackName: Utilizado para darle un nombre al stack de CloudFormation
*/
if (GIT_BRANCH == "origin/develop") {
  s3bucket = "${env.S3BUCKET_NAME}"
  doLocal = false
  doTests = true
  stackName = "dev"
} else if (GIT_BRANCH == "origin/staging") {
  s3bucket = "${env.S3BUCKET_NAME}"
  doLocal = false
  doTests = true
  stackName = "stg"
} else if (GIT_BRANCH == "origin/master") {
  s3bucket = "${env.S3BUCKET_NAME}"
  doLocal = false
  doTests = false
  stackName = "prod"
} else {
  doLocal = true
  doTests = true
  stackName = "local"
}


/*
  Esta función limpia el entorno.
    - debugenv: Utilizado para imprimir información acerca del entorno
*/
def cleanUp(debugenv) {
  stage('Clean') {
    deleteDir()
    if (debugenv) {
      sh 'printenv'
    }
  }
}

/*
  Esta función crea/elimina la red en docker
    - action: create o remove
    - timeInSeconds: número que se genera para darle un nombre "único" a los recursos
*/
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

/*
  Esta función crea/elimina el contenedor con el entorno de build
    - action: create o remove
    - timeInSeconds: número que se genera para darle un nombre "único" a los recursos
    - doTests: si vamos a hacer tests linkeamos el container de dynamodb
*/
def pythonBuildEnv(action, timeInSeconds, doTests) {
  switch(action) {
    case 'create':
      stage('Create Build Environment') {
        if (doTests) {
          sh "docker container run --name python-env-${timeInSeconds} --link dynamodb-${timeInSeconds}:dynamodb --network aws-${timeInSeconds} -di -v /var/run/docker.sock:/var/run/docker.sock -v \${HOME}/.aws:/home/builduser/.aws -v \${PWD}:\${PWD} ${env.ECR_PYTHON}"
        } else {
          sh "docker container run --name python-env-${timeInSeconds} --network aws-${timeInSeconds} -di -v /var/run/docker.sock:/var/run/docker.sock -v \${HOME}/.aws:/home/builduser/.aws -v \${PWD}:\${PWD} ${env.ECR_PYTHON}"
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

/*
  Esta función crea/elimina el contenedor de dynamodb
    - action: create o remove
    - timeInSeconds: número que se genera para darle un nombre "único" a los recursos
    - doTests: sólo iniciaremos dynamodb si necesitamos hacer tests
*/
def localDynamo(action, timeInSeconds, doTests) {
  switch(action) {
    case 'create':
      stage('Create local dynamodb') {
        if (doTests) {
          sh "docker container run -d --network aws-${timeInSeconds} --name dynamodb-${timeInSeconds} --rm amazon/dynamodb-local"
        } else {
          echo "Este entorno no ejecutará tests, por lo que no es necesario iniciar DynamoDB-Local"
        }
      }
      break;
    case 'remove':
      stage('Remove local dynamodb') {
        if (doTests) {
          sh "docker container rm -f dynamodb-${timeInSeconds}"
        } else {
          echo "Este entorno no ejecutó tests, por lo que no es necesario detener DynamoDB-Local (No iniciado)"
        }
      }
      break;
  }
}

/*
  Esta función se utiliza para lanzar las distintas pruebas
    - timeInSeconds: número que se genera para darle un nombre "único" a los recursos
    - doLocal: para saber si estamos trabajando en un entorno local
    - doTests: sólo lanzaremos las pruebas que así lo requieran
    - testCase: static, unittest o integration
*/
def testApp(timeInSeconds, doLocal, doTests, testCase) {
  switch(testCase) {
    case 'static':
      stage('Run tests 1/2 - Static tests') {
        if (doTests) {
          sh "docker container exec -i python-env-${timeInSeconds} /opt/todo-list-aws/tests/run_tests.sh"
        } else {
          echo "Este entorno no ejecutará tests"
        }
      }
      break;
    case 'unittest':
      stage('Run tests 2/2 - unittest') {
        if (doTests) {
          sh "docker container exec -i python-env-${timeInSeconds} /opt/todo-list-aws/tests/run_unittest.sh"
        } else {
          echo "Este entorno no ejecutará tests"
        }
      }
      break;
    case 'integration':
      stage('Run integration tests') {
        if (doLocal) {
          sh "docker container exec -w \${PWD} -i python-env-${timeInSeconds} /opt/todo-list-aws/tests/run_integration.sh ${stackName}"
        } else {
          sh "docker container exec -w \${PWD} -i python-env-${timeInSeconds} /opt/todo-list-aws/tests/run_integration.sh ${stackName}"
        }
      }
  }
}

/*
  Esta función se utiliza para crear un symlink en el entorno de build para trabajar en /opt/todo-list-aws
    - timeInSeconds: número que se genera para darle un nombre "único" a los recursos
    - source: Directorio de origen (/var/lib/jenkins/wokspace/...)
    - destination: Directorio de destino (/opt/todo-list-aws)
*/
def linkDirectory(timeInSeconds, source, destination) {
  sh "docker container exec -u root python-env-${timeInSeconds} ln -sf ${source} ${destination}"
}

/*
  Esta función se utiliza para iniciar local-api
    - timeInSeconds: número que se genera para darle un nombre "único" a los recursos
    - doTests: sólo iniciaremos local-api si necesitamos hacer tests
*/
def startLocalApi(timeInSeconds, doTests) {
  stage("Start sam local-api") {
    if (doTests) {
      sh "docker container exec -d -w \${PWD} python-env-${timeInSeconds} sed -i 's/timeInSeconds/${timeInSeconds}/g' todos/todoTableClass.py"
      sh "docker container exec -d -w \${PWD} python-env-${timeInSeconds} /home/builduser/.local/bin/sam local start-api --region us-east-1 --host 0.0.0.0 --port 8080 --debug --docker-network aws-${timeInSeconds} --docker-volume-basedir \${PWD}"
      // Wait 10 seconds for api to start
      sleep 10
    } else {
      echo "Este entorno no ejecutará tests, por lo que no es necesario iniciar local-api"
    }
  }
}

/*
  Esta función se utiliza para construir la app
    - timeInSeconds: número que se genera para darle un nombre "único" a los recursos
    - doLocal: para saber si estamos trabajando en un entorno local
    - stackName: para trabajar sobre un stack de CloudFormation
*/
def buildApp(timeInSeconds, doLocal, stackName) {
  stage('Build application') {
    if (!doLocal) {
      sh "docker container exec -i -w \${PWD} python-env-${timeInSeconds} /home/builduser/.local/bin/sam build --region us-east-1 --debug --docker-network aws-${timeInSeconds} --parameter-overrides EnvironmentType=${stackName}"
    } else {
      echo "No construiremos la app en un entorno local"
    }
  }
}

/*
  Después de construir la app validamos si el template funciona
    - timeInSeconds: número que se genera para darle un nombre "único" a los recursos
    - doLocal: para saber si estamos trabajando en un entorno local
*/
def validateApp(timeInSeconds, doLocal) {
  stage('Validate cloudformation template') {
    if (!doLocal) {
      sh "docker container exec -i -w \${PWD} python-env-${timeInSeconds} /home/builduser/.local/bin/aws cloudformation validate-template --template-body file://.aws-sam/build/template.yaml"
    } else {
      echo "No hemos construido una app para validar en un entorno local"
    }
  }
}

/*
  Esta función despliega SAM
    - timeInSeconds: número que se genera para darle un nombre "único" a los recursos
    - doLocal: para saber si estamo trabajando en un entorno local
    - stackName: para trabajar sobre un stack de CloudFormation
*/
def deployApp(timeInSeconds, doLocal, stackName, s3bucket) {
  stage('Deploy application') {
    if (!doLocal) {
      sh "docker container exec -i -w \${PWD} python-env-${timeInSeconds} /home/builduser/.local/bin/sam deploy --region us-east-1 --debug --force-upload --stack-name todo-list-aws-${stackName} --debug --s3-bucket ${s3bucket} --capabilities CAPABILITY_NAMED_IAM --parameter-overrides EnvironmentType=${stackName}"
    } else {
      echo "No hemos construído ni validado la app en un entorno local para desplegar"
    }
  }
}

/*
  Función utilizada para hacer debug de errores
    - e: string de excepción
*/
def printFailure(e) {
  println "Failed because of $e"
}


/*
  Comienzo del pipeline
*/
node {
  // Limpiamos el entorno
  cleanUp(true)

  // Obtenemos la última versión del código desde Git
  stage('Checkout') {
    echo 'Checkout SCM'
    checkout scm
  }

  // Descargamos las imágenes de docker que vamos a utilizar
  stage('Pull docker images') {
    sh "docker image pull ${env.ECR_PYTHON}"
    sh "docker image pull amazon/dynamodb-local"
  }

  try {
    // Creamos la red de docker
    dockerNetwork('create', timeInSeconds)
    try {
      // Iniciamos dynamodb-local
      localDynamo('create', timeInSeconds, doTests)

      try {
        // Iniciamos nuestro entorno de build
        pythonBuildEnv('create', timeInSeconds, doTests)

        try {
          // Creamos symlink del directorio
          linkDirectory(timeInSeconds, WORKSPACE, "/opt/todo-list-aws")

          // Testeamos el código y realizmos unittests
          testApp(timeInSeconds, doLocal, doTests, 'static')
          testApp(timeInSeconds, doLocal, doTests, 'unittest')

          // Iniciamos local-api
          startLocalApi(timeInSeconds, doTests)

          try {
            // Construimos, validamos y desplegamos la app
            buildApp(timeInSeconds, doLocal, stackName)
            validateApp(timeInSeconds, doLocal)
            deployApp(timeInSeconds, doLocal, stackName, s3bucket)
          } catch(da) {
            // Fallo al construir o desplegar la app
            printFailure(da)
            currentBuild.result = "FAILURE"
          }

          // Realizamos integration test
          testApp(timeInSeconds, doLocal, doTests, 'integration')
        } catch(r) {
          // Si Algo falló mostramos un error
          printFailure(r)
          currentBuild.result = "FAILURE"
        } finally {
          // Siempre eliminamos el entorno de build
          pythonBuildEnv('remove', timeInSeconds, doLocal)
        }

      } catch(ld) {
        // Si no pudimos iniciar el entorno de build mostramos error
        printFailure(ld)
        currentBuild.result = "FAILURE"
      } finally {
        // Siempre eliminamos dynamodb-local
        localDynamo('remove', timeInSeconds, doTests)
      }

    } catch(be) {
      // Si no pudimos iniciar dynamodb-local mostramos error
      printFailure(be)
      currentBuild.result = "FAILURE"
    } finally {
      // Siempre eliminamos la red de docker
      dockerNetwork('remove', timeInSeconds)
    }

  } catch(dn) {
    // Si no pudimos iniciar la red de docker mostramos un error
    printFailure(dn)
    currentBuild.result = "FAILURE"
  }

  // Limpiamos el entorno
  cleanUp(false)
}
