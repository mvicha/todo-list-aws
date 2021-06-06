# REST AWS

Este Pipeline permite la ejecución de múltiples branches. Los requerimientos para que funciones son:

- docker (utilizado para levantar entorno de desarrollo. Pipeline incluído en el repositorio):
    > ssh://git-codecommit.us-east-1.amazonaws.com/v1/repos/python-env
- usuario de codecommit con su clave ssh. Instrucciones de instalación en la guía de procedimientos

## Funcionamiento:
  Este pipeline funciona en cualquier entorno/rama. Actualmente está definido para que funcione de la siguiente manera:
  - Entorno: Desarrollo - Rama: develop - Job: Todo-List-Dev-Pipeline
  - Entorno: Pruebas - Rama: staging - Job: Todo-List-Staging-Pipeline
  - Entorno: Producción - Rama: master - Job: Todo-List-Production-Pipeline

### El ciclo de vida sería el siguiente:
  - Comenzamos trabajando en una rama descendiente de develop, por ejemplo feature-A.
  - Al terminar nuestro trabajo en feature-A haremos un pull request a develop
  - Al aprobarse develop ejecutaremos el pipeline del entorno de desarrollo (Todo-List-Develop-Pipeline)
  - Cuando estemos seguros que desarrollo está listo para promoverse haremos un pull request de develop a staging
  - Ejecutaremos el pipeline de staging (Todo-List-Staging-Pipeline)
  - Cuando estemos seguros que staging está listo para promoverse como estable haremos un pull request de staging a master
  - Ejecutaremos el pipeline de producción (Todo-List-Production-Pipeline)

#### Ejecución de todos los trabajos a la vez.
  Existe un Job que se llama <b>Todo-List-Full-Pipeline</b>, este se ejecuta paso a paso desde desarrollo hasta producción.
  Cada ejecución exitosa del entorno anterior hará que los cambios del entorno sean incorporados en el siguiente nivel, y ejecutará el pipeline del nivel correspondiente, hasta llegar a producción

## Guía de procedmientos:
  Lo primero que debemos tener en cuenta es que este trabajo práctico tiene ciertos requerimientos. Para facilitar la instalación y despliegue de los mismos se han incluído algunas notas y se han mejorado algunos de los procesos que habían sido provistos para llevar a cabo dichos trabajos.

  Dividiremos estos pasos en despliegue en entorno local y despliegue en entorno cloud.

  Los pasos se detallan a continuación para ambos entornos:

### Despliegue en entorno local:
  Para desplegar en el entorno local utilizaremos el script ubicado en utils/runlocal.sh. Este script realiza las siguientes tareas:
  - Crear el entorno local de desarrollo
  - Ejecutar pruebas de código estático
  - Inicializar SAM API
  - Ejecutar pruebas de integración
  - Construir el changeset de la aplicación y validarlo
  - Desplegar el changeset a un entorno cloud desde el ambiente local
  - Eliminar el despliegue de un entorno cloud
  - Destruir el entorno de desarrollo local

  Para llevar a cabo el despliegue procederemos de la siguiente manera:
  1) Creación del entorno local de desarrollo:
  ```bash
  utils/runlocal.sh create
  ```

  2) Ejecución de pruebas de código estático
  ```bash
  utils/runlocal.sh run-static-tests
  ```

  3) Inicialización de SAM API local (Esta ejecución a diferencia de las anteriores seguirá corriendo mientras no se cancele
    con CTRL+C.)
  ```bash
  utils/runlocal.sh run-api
  ```

  4) Ejecución de pruebas de integración (Esta ejecución deberá realizarse desde otra terminal sin cancelar la ejecución de
    SAM API local)
  ```bash
  utils/runlocal.sh run-integration-tests local
  ```

    > *NOTA:* la ejecución de pruebas de integración permitiría testear entornos desplegados en la nube. Para ello en vez de incluir el parámetro "local", deberíamos incluir el parámetro del entorno que queremos verificar. Los valores soportados son: "local", "dev", "stg" y "prod"

  5) Creación del changeset
  ```bash
  utis/runlocal.sh build "dev"
  ```

    > *NOTA:* Como en el caso anterior, esta ejecución permite la creación de nuestro build para los distintos ambientes mediante el paso del entorno. Los valores sportados son: "*dev*", "*stg*" y "*prod*"

  6) Despliegue del entorno
  ```bash
  utils/runlocal.sh deploy "dev"
  ```

    > *NOTA:* Como en el caso anterior, esta ejecución permite el despliegue del entorno en el ambiente cloud mediante los parámetros provistos. Los valores sportados son: "*dev*", "*stg*" y "*prod*"

  7) Eliminación del despliegue de un ambiente cloud
  ```bash
  utils/runlocal.sh undeploy "dev"
  ```

    > *NOTA:* Como en el caso anterior, esta ejecución permite la eliminación del despliegue del ambiente cloud mediante los parámetros provistos. Los valores sportados son: "*dev*", "*stg*" y "*prod*"

  8) Destrucción del entorno de desarrollo local
  ```bash
  utils/runlocal.sh destroy
  ```

  Pueden presentarse errores al momento de la ejecución. Si se encontrara con un error similar a:

  > Unable to find image '750489264097.dkr.ecr.us-east-1.amazonaws.com/mvicha-ecr-python-env:latest' locally

  > docker: Error response from daemon: Head https://750489264097.dkr.ecr.us-east-1.amazonaws.com/v2/mvicha-ecr-python-env/manifests/latest: no basic auth credentials.

  Se debe a que no tiene las credenciales configuradas para poder descargar las imágenes del entorno local. Debería ejecutar lo siguiente para resolver el problema, y volver a intentar la ejecución:
  ```bash
  aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin https://750489264097.dkr.ecr.us-east-1.amazonaws.com/v2/mvicha-ecr-python-env
  ```
  Reemplaza la URL del endpoint dkr por la provista por terraform output (ver más adelante)


## Despliegue en un entorno Cloud
### Configurar Cloud9:
    1) Para configurar Cloud9 se proporciona un template en CloudFormation que incluye todo lo necesario para desplegar el entorno. El archivo README.md proporciona las instrucciones necesarias para desplegar el entorno:
        URL: git@github.com:mvicha/cloud9-env.git
        BRANCH: dev
      ```bash
      git clone git@github.com:mvicha/cloud9-env.git -b dev
      cd cloud9-env
      > Seguir las instrucciones de README.md
      ```

### Configurar Jenkins:
  - El entorno de Jenkins ha sido creado por completo desde cero, ya que en algún momento la imágen de Jenkins dejó de existir y para seguir trabajando tuve que crear una propia. Se disponen de varias variables que deben ser modificadas en el archivo *variables.tf*. Se detallan a continuación:

    * *create_repositories*
      Esta variable acepta los valores "*true*" o "*false*", y lo que nos permite es indicarle a terraform si queremos crear o no los repositorios en CodeCommit donde se guardará el código.

      En el caso de disponer de un repositorio se puede setear en "*false*" y setear las variables "*todo_list_repo*" "*python_env_repo*"

```
python_env_repo
  Esta variable se utiliza en el caso de que "*create_repositories*" sea "*false*" como parámetro del pipeline de "*Python-Env*"
```

```
  todo_list_repo
  Esta variable se utiliza en el caso de que "*create_repositories*" sea "*false*" como parámetro de los pipeline  "*TODO-LIST...*"
```

```
  jenkinsHome
  No es necesario modificar esta variable, y se recomienda no hacerlo. Esta variable se utiliza para definir el directorio HOME para la aplicación de Jenkins
```

```
  jenkinsVolume
  No es necesario modificar esta variable, y se recomienda no hacerlo. Esta variable se utiliza para definir el directorio que se utilizará en el servidor como Volumen para compartir con el entorno Docker
```

```
  jenkinsHttp / jenkinsHttps
  No es necesario modificar estas variable. Se utilizan para definir los puertos HTTP y HTTPS que queremos utilizar para conectarnos a Jenkins
```

```
  jenkinsUser / jenkinsPassword
  Requerido setear estas variables. Serán utilizadas para configurar el usuario / contraseña del usuario con permisos de administrador de Jenkins
```

    - Con el entorno desplegado ejecutamos terraform para iniciar nuestro entorno de Jenkins. Este terraform ha sido ampliado para incluir la creación de unos ECRs (Elastic Container Registries), en el que se guardaran algunas imágenes de contenedores requeridas para que todo funcione.
        * ecr_python_env: Contiene un entorno de desarrollo para hacer el despliegue
      Los pasos a seguir son los siguientes:
        * Crear un bucket en s3 para guardar los estados de terraform:
          ```bash
          aws s3api create-bucket --bucket <nombre-del-bucket> --region us-east-1
          ```
        * Inicializar terraform:
          La versión de terraform que utilizamos en este caso es Terraform v0.14.3. Si ejecuta otra version puede que se requiera realizar cambios para que el entorno se despliegue de la manera apropiada.

          Edita el archivo de variables.tf dentro del directorio terraform. En el mismo encontrarás la variable ecr_python_env_name, que debe contener el nombre del ECR que se creará para guardar la imágen de docker

          Si no se utilizara el default profile de AWS se debería exportar el valor a utilizar:
          ```bash
            export AWS_PROFILE=unir
          ```

          Toma nota de la  dirección IP en tu máquina local, la necesitarás para ejecutar terraform. para conseguirla puedes ejecutar:
          ```bash
            export TF_VAR_myip=$(dig +short myip.opendns.com @resolver1.opendns.com)
          ```

          Ahora con esos datos puedes ejecutar terraform. Esto creará el entorno de Jenkins
          ```bash
            ./terraform init
            ./terraform plan -out=plan.out
            ./terraform apply plan.out
          ```

        - Qué pasos realiza el proceso de Terraform:
           1) Creación de VPC
           2) Creación de Subnets
           3) Creación de Security Groups
           4) Creación de codecommit user
           5) Asignación de privilegios CodeCommit Full al usuario codecommit recientemente creado
           6) Creación de DKR para guardar la imágen de python-env
           7) (opcional) Creación del repositorio python-env
           8) (opcional) Creación del repositorio todo-list-aws
           9) Despliegue de la instancia de Jenkins
          10) Configuración de Jobs de Jenkins

          EL PROCESO DE TERRAFORM AUTOMÁTICAMENTE CONFIGURA LOS JOBS CON LOS PARÁMETROS REQUERIDOS GRACIAS A LA EJECUCIÓN DE user-data.
          El proceso en sí descarga un repositorio con los jobs y los parametriza, luego reinicia el servicio de Jenkins para que los Jobs queden configurados

  1) Configuración del usuario de CodeCommit:
    El usuario de CodeCommit tiene una llave de SSH asociada, si no se ha creado todavía los pasos para la creación son los siguientes:
      * En Jenkins ir a Administrar Jenkins - Manejo de credenciales
      * Hacer click en Dominio Global y luego en Agregar credenciales
        - Tipo: SSH Username with private key
        - Scope: Global
        - ID: codecommit
        - Descripción: Llave que se utilizará para conectar a codecommit
        - Username: El ID que obtenemos en la salida de Terraform: codecommit_key_id
        - Private key (Enter directly): Pegar la clave de la salida de Terraform: key_pair_codecommit

  4) Ejecución de Jobs:
    - El primer Job que debemos ejecutar es el de ENABLE-UNIR-CREDENTIALS. Este Job ha sido modificado para solicitar ECR_URL como parámetro. Esto es para iniciar sesión. Este parámetro lo obenemos de la ejecución de terraform anterior bajo el output ecr_python_env_url. En el caso de haber perdido el output se puede recuperar:
  ```bash
        terraform output.
  ```
    - El siguiente Job que debemos ejecutar es el de Python-Env
    - Luego sólo nos queda ejecutar nuestro pipeline de desarrollo Todo-List-Dev-Pipeline o el que queramos ejecutar.

  * NOTA PARA IMPORTAR REPOSITORIOS:*
    Seguramente tengamos que imoprtar los repositorios de python-env y todo-list-aws en los reciéntemente creados por Teraform. Se entrega un script (utils/fix.sh) que facilitará la tarea. Este script recibe como parámetros el path del directorio del alumno y la nueva url del repositorio.

     A continuación un ejemplo:
    ```bash
      utils/fix.sh todo-list-aws git@github.com:mvicha/todo-list-aws.git ssh://git-codecommit.us-east-1.amazonaws.com/v1/repos/todo-list-aws-tf
    ```

## Estructura

Este repositorio consta de directorio separado para todas las operaciones de la lista de ToDos en Python. Para cada operación existe exactamente un fichero, por ejemplo "todos/delete.py". En cada uno de estos archivos hay exactamente una función definida.

La idea del directorio `todos` es que en caso de que se quiera crear un servicio que contenga múltiples recursos, por ejemplo, usuarios, notas, comentarios, se podría hacer en el mismo servicio. Aunque esto es ciertamente posible, se podría considerar la creación de un servicio separado para cada recurso. Depende del caso de uso y de la preferencia del desarrollador.

La estructura actual del repositorio sería la siguiente:

```
├── pipeline
│   ├── ENABLE-UNIR-CREDENTIALS
│   │   └── Jenkinsfile
│   ├── PIPELINE-FULL-CD
│   │   └── Jenkinsfile
│   ├── PIPELINE-FULL-PRODUCTION
│   │   └── Jenkinsfile
│   ├── PIPELINE-FULL-STAGING
│   │   └── Jenkinsfile
│   └── Python-Env
│       └── Jenkinsfile
├── README.md
├── terraform
│   ├── codecommit.tf
│   ├── configure_environment.sh
│   ├── ebs.tf
│   ├── ecr.tf
│   ├── iam.tf
│   ├── locals.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── resources
│   │   └── get-ssh-key.sh
│   ├── s3.tf
│   ├── security.tf
│   ├── ssh.tf
│   ├── state.tf
│   ├── templates
│   │   └── setup.tpl
│   ├── var.tfvars
│   └── variables.tf
├── tests
│   ├── example
│   │   ├── README.md
│   │   ├── TestToDo.py
│   │   ├── ToDoCreateTable.py
│   │   ├── ToDoDeleteItem.py
│   │   ├── ToDoGetItem.py
│   │   ├── ToDoListItems.py
│   │   ├── ToDoPutItem.py
│   │   └── ToDoUpdateItem.py
│   ├── integration
│   │   ├── integrationClass.py
│   │   ├── requirements.txt
│   │   └── test_integration.py
│   ├── run_integration.sh
│   ├── run_tests.sh
│   └── run_unittest.sh
├── todos
│   ├── __init__.py
│   ├── create.py
│   ├── decimalencoder.py
│   ├── delete.py
│   ├── get.py
│   ├── list.py
│   ├── requirements.txt
│   ├── todoTableClass.py
│   ├── translate.py
│   └── update.py
├── utils
│   ├── fix.sh
│   ├── runlocal.sh
│   └── setup.sh
├── .gitignore
├── CHANGELOG.md
├── Jenkinsfile
├── README.md
├── env.json
├── table.json
└── template.json
```

Directorios a tener en cuenta:

- pipeline: en este directorio el alumno deberá de persistir los ficheros Jenkinsfile que desarrolle durante la práctica. Si bien es cierto que es posible que no se puedan usar directamente usando los plugins de Pipeline por las limitaciones de la cuenta de AWS, si es recomendable copiar los scripts en groovy en esta carpeta para su posterior corrección. Se ha dejado el esqueleto de uno de los pipelines a modo de ayuda, concretamente el del pipeline de PIPELINE-FULL-STAGING.
- test: en este directorio se almacenarán las pruebas desarrolladas para el caso práctico. A COMPLETAR POR EL ALUMNO
- terraform: en este directorio se almacenan los scripts necesarios para levantar la infraestructura necesaria para el apartado B de la práctica. Para desplegar el contexto de Jenkins se ha de ejecutar el script de bash desde un terminal de linux (preferiblemente en la instancia de Cloud9). Durante el despliegue de la infraestructura, se solicitará la IP del equipo desde donde se va a conectar al servidor de Jenkins. Puedes consultarla previamente aquí: [cualesmiip.com](https://cualesmiip.com)
- todos: en este directorio se almacena el código fuente de las funciones lambda con las que se va a trabajar









# Serverless REST API

Este ejemplo demuestra cómo configurar un [Servicios Web RESTful](https://en.wikipedia.org/wiki/Representational_state_transfer#Applied_to_web_services) que le permite crear, listar, obtener, actualizar y borrar listas de Tareas pendientes(ToDo). DynamoDB se utiliza para persistir los datos.

Este ejemplo está obtenido del [repositorio de ejemplos](https://github.com/serverless/examples/tree/master/aws-python-rest-api-with-dynamodb) de Serverless Framework. Debido a que el objetivo de la práctica es implementar una serie de Pipelines de CI/CD de diferente manera, el objetivo principal del alumno no será codificar desde cero un servicio. Por eso se ha elegido este caso que aunque no es excesivamente complejo, si representa un reto en determinados puntos, al ser un ecosistema al que probablemente el alumno no estará acostumbrado.

## Estructura

Este repositorio consta de directorio separado para todas las operaciones de la lista de ToDos en Python. Para cada operación existe exactamente un fichero, por ejemplo "todos/delete.py". En cada uno de estos archivos hay exactamente una función definida.

La idea del directorio `todos` es que en caso de que se quiera crear un servicio que contenga múltiples recursos, por ejemplo, usuarios, notas, comentarios, se podría hacer en el mismo servicio. Aunque esto es ciertamente posible, se podría considerar la creación de un servicio separado para cada recurso. Depende del caso de uso y de la preferencia del desarrollador.

La estructura actual del repositorio sería la siguiente:

```
├── package.json (APARTADO A)
├── pipeline (APARTADO B)
│   ├── ENABLE-UNIR-CREDENTIALS
│   │   └── Jenkinsfile
│   ├── PIPELINE-FULL-CD
│   │   └── Jenkinsfile
│   ├── PIPELINE-FULL-PRODUCTION
│   │   └── Jenkinsfile
│   └── PIPELINE-FULL-STAGING
│       └── Jenkinsfile
├── README.md
├── serverless.yml (APARTADO A)
├── terraform (APARTADO B)
│   ├── configure_environment.sh
│   ├── main.tf
│   ├── outputs.tf
│   ├── resources
│   │   └── get-ssh-key.sh
│   ├── variables.tf
│   └── var.tfvars
├── test
│   ├── example
│   │   ├── README.md
│   │   ├── TestToDo.py
│   │   ├── ToDoCreateTable.py
│   │   ├── ToDoDeleteItem.py
│   │   ├── ToDoGetItem.py
│   │   ├── ToDoListItems.py
│   │   ├── ToDoPutItem.py
│   │   └── ToDoUpdateItem.py
│   ├── integration
│   └── unit
└── todos
    ├── create.py
    ├── decimalencoder.py
    ├── delete.py
    ├── get.py
    ├── __init__.py
    ├── list.py
    ├── todoTableClass.py
    └── update.py
```

Directorios a tener en cuenta:

- pipeline: en este directorio el alumno deberá de persistir los ficheros Jenkinsfile que desarrolle durante la práctica. Si bien es cierto que es posible que no se puedan usar directamente usando los plugins de Pipeline por las limitaciones de la cuenta de AWS, si es recomendable copiar los scripts en groovy en esta carpeta para su posterior corrección. Se ha dejado el esqueleto de uno de los pipelines a modo de ayuda, concretamente el del pipeline de PIPELINE-FULL-STAGING.
- test: en este directorio se almacenarán las pruebas desarrolladas para el caso práctico. A COMPLETAR POR EL ALUMNO
- terraform: en este directorio se almacenan los scripts necesarios para levantar la infraestructura necesaria para el apartado B de la práctica. Para desplegar el contexto de Jenkins se ha de ejecutar el script de bash desde un terminal de linux (preferiblemente en la instancia de Cloud9). Durante el despliegue de la infraestructura, se solicitará la IP del equipo desde donde se va a conectar al servidor de Jenkins. Puedes consultarla previamente aquí: [cualesmiip.com](https://cualesmiip.com)
- todos: en este directorio se almacena el código fuente de las funciones lambda con las que se va a trabajar

## Casos de uso

- API for a Web Application
- API for a Mobile Application

## Configuración

```bash
npm install -g serverless@2.18
```

**Importante:** revisar la guía para instalar la correcta versión de serverless para evitar fallos con el login de Serverless Framework

## Despliegue con Serverless Framework

De cara a simplificar el despliegue, simplemente habría que ejecutar

```bash
serverless deploy
```

Los resultados esperados deberían de ser así:

```bash
Serverless: Packaging service…
Serverless: Uploading CloudFormation file to S3…
Serverless: Uploading service .zip file to S3…
Serverless: Updating Stack…
Serverless: Checking Stack update progress…
Serverless: Stack update finished…

Service Information
service: api-rest
stage: dev
region: us-east-1
api keys:
  None
endpoints:
  POST - https://45wf34z5yf.execute-api.us-east-1.amazonaws.com/dev/todos
  GET - https://45wf34z5yf.execute-api.us-east-1.amazonaws.com/dev/todos
  GET - https://45wf34z5yf.execute-api.us-east-1.amazonaws.com/dev/todos/{id}
  PUT - https://45wf34z5yf.execute-api.us-east-1.amazonaws.com/dev/todos/{id}
  DELETE - https://45wf34z5yf.execute-api.us-east-1.amazonaws.com/dev/todos/{id}
functions:
  api-rest-dev-update: arn:aws:lambda:us-east-1:488110005556:function:serverless-rest-api-with-dynamodb-dev-update
  sapi-rest-dev-get: arn:aws:lambda:us-east-1:488110005556:function:serverless-rest-api-with-dynamodb-dev-get
  api-rest-dev-list: arn:aws:lambda:us-east-1:488110005556:function:serverless-rest-api-with-dynamodb-dev-list
  api-rest-dev-create: arn:aws:lambda:us-east-1:488110005556:function:serverless-rest-api-with-dynamodb-dev-create
  api-rest-dev-delete: arn:aws:lambda:us-east-1:488110005556:function:serverless-rest-api-with-dynamodb-dev-delete
```

## Despliegue infraestructura de Terraform para el Apartado B

En la instancia de Cloud9, simplemente se ha de ejecutar el script de `configure_enviroment.sh`, dentro del directorio de [terraform](https://registry.terraform.io/).
Cuando se pregunte por la IP, [indicar la del equipo](https://cualesmiip.com) desde donde se desea conectar.

```bash
$ cd terraform
$ ./configure_environment.sh

$ ./terraform plan -out=plan
var.myip
  A continuación indicar la IP desde donde se va a conectar al servidor web y la instancia ec2

  Enter a value: 57.123.221.88 # IP de ejemplo, sustituir por la personal!

$ ./terraform apply plan

...
Apply complete! Resources: 8 added, 0 changed, 8 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate

Outputs:

jenkins_instance_id = "i-03182e2534954fdf5"
jenkins_instance_security_group_id = "sg-0e00e629e32749ec5"
jenkins_url = "http://112.23.18.67:8080"
key_pair = <<EOT
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAsk5rieVA2zwpo86gAZGq37L4aRCC2YeHxZ4LxFqTJ1e+9pHB
....
S6Vm27ZFT3Rbbt1KRB64AlfLGEZ+hB07JVzz4RSQvZkUw3Whosk8qUQ=
-----END RSA PRIVATE KEY-----

EOT
public_ip = "112.23.18.67"
s3_bucket_production = "es-unir-production-s3-XXXXX-artifacts"
s3_bucket_staging = "es-unir-production-s3-XXXXX-artifacts"
ssh_connection = "ssh -i resources/key.pem ec2-user@112.23.18.67"
  ...
```

Este script genera una serie de salidas:

- Por un lado genera una serie de ficheros que son necesarios de mantener, pero que no deben subirse al repositorio, como son

  - `terraform`: ejecutable de terraform
  - `terraform.tfstate`: estado de los recursos desplegados con terraform
  - `.terraform.lock.hcl`: fichero de bloqueo de los recursos desplegados con terraform, para evitar problemas de dependencias.
  - `resources/key.pem`: la clave para acceder a la instancia EC2.
- Por otro lado está la salida del propio script, que genera las siguientes salidas:

  - `jenkins_instance_id` = Identificador de la instancia EC2 levantada en la cuenta de AWS, e.g:`"i-03182e2534954fdf5"`
  - `jenkins_instance_security_group_id` = Identificador del Security Group que usa la EC2 levantada en la cuenta de AWS, e.g:`"sg-0e00e629e32749ec5"`
  - `jenkins_url` = URL del servidor de Jenkins desplegado. La contraseña de acceso se encuentra disponible en la guía de la práctica. e.g:`"http://112.23.18.67:8080"`
  - `key_pair` = Clave privada para acceder a la instancia EC2 levantada por SSH.
  - `public_ip` = Dirección IP de la instancia EC2 levantada en la cuenta de AWS, e.g:`"112.23.18.67"`
  - `s3_bucket_production` = Bucket de S3 levantado en la cuenta de AWS, para persistir los artefactos del pipeline de production en Jenkins, e.g:`"es-unir-production-s3-XXXXX-artifacts"`
  - `s3_bucket_staging` = Bucket de S3 levantado en la cuenta de AWS, para persistir los artefactos del pipeline de production en Jenkins, e.g:`"es-unir-production-s3-XXXXX-artifacts"`
  - `ssh_connection` = Conexión ssh para acceder al servidor de Jenkins, e.g`"ssh -i resources/key.pem ec2-user@112.23.18.67"`

**Importante:** Si se desea desplegar desde un equipo local y no desde Cloud9 -recordar que este script está pensado para ejecutar en un entorno de Linux y que desde local-, hay que configurar las credenciales temporales de la cuenta de AWS Educate dentro del fichero `~/.aws./credentials` del `home` del usuario.

## Uso

Se puede crear, lista, coger, actualizar y borrar una tarea, ejecutando los siguientes comandos `curl` desde la línea de comandos del terminal:

### Crear una tarea

```bash
curl -X POST https://XXXXXXX.execute-api.us-east-1.amazonaws.com/dev/todos --data '{ "text": "Learn Serverless" }'
```

No hay salida

### Listar todas las tareas

```bash
curl https://XXXXXXX.execute-api.us-east-1.amazonaws.com/dev/todos
```

Ejemplo de salida:

```bash
[{"text":"Deploy my first service","id":"ac90feaa11e6-9ede-afdfa051af86","checked":true,"updatedAt":1479139961304},{"text":"Learn Serverless","id":"206793aa11e6-9ede-afdfa051af86","createdAt":1479139943241,"checked":false,"updatedAt":1479139943241}]%
```

### Coger una tarea

```bash
# Replace the <id> part with a real id from your todos table
curl https://XXXXXXX.execute-api.us-east-1.amazonaws.com/dev/todos/<id>
```

Ejemplo de salida:

```bash
{"text":"Learn Serverless","id":"ee6490d0-aa11e6-9ede-afdfa051af86","createdAt":1479138570824,"checked":false,"updatedAt":1479138570824}%
```

### Actualizar una tarea

```bash
# Replace the <id> part with a real id from your todos table
curl -X PUT https://XXXXXXX.execute-api.us-east-1.amazonaws.com/dev/todos/<id> --data '{ "text": "Learn Serverless", "checked": true }'
```

Ejemplo de salida:

```bash
{"text":"Learn Serverless","id":"ee6490d0-aa11e6-9ede-afdfa051af86","createdAt":1479138570824,"checked":true,"updatedAt":1479138570824}%
```

### Borrar una tarea

```bash
# Replace the <id> part with a real id from your todos table
curl -X DELETE https://XXXXXXX.execute-api.us-east-1.amazonaws.com/dev/todos/<id>
```

No output

## Escalado

### AWS Lambda

Por defecto, AWS Lambda limita el total de ejecuciones simultáneas en todas las funciones dentro de una región dada a 100. El límite por defecto es un límite de seguridad que le protege de los costes debidos a posibles funciones desbocadas o recursivas durante el desarrollo y las pruebas iniciales. Para aumentar este límite por encima del predeterminado, siga los pasos en [Solicitar un aumento del límite para las ejecuciones simultáneas] (http://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html#increase-concurrent-executions-limit).

### DynamoDB

Cuando se crea una tabla, se especifica cuánta capacidad de rendimiento provisto se quiere reservar para lecturas y escritos. DynamoDB reservará los recursos necesarios para satisfacer sus necesidades de rendimiento mientras asegura un rendimiento consistente y de baja latencia. Usted puede cambiar el rendimiento provisto y aumentar o disminuir la capacidad según sea necesario.

Esto se puede hacer a través de los ajustes en el `serverless.yml`.

```yaml
  ProvisionedThroughput:
    ReadCapacityUnits: 1
    WriteCapacityUnits: 1
```

En caso de que esperes mucha fluctuación de tráfico, te recomendamos que consultes esta guía sobre cómo escalar automáticamente el DynamoDB [https://aws.amazon.com/blogs/aws/auto-scale-dynamodb-with-dynamic-dynamodb/](https://aws.amazon.com/blogs/aws/auto-scale-dynamodb-with-dynamic-dynamodb/)







docker image build -t casopracticounir:1.0-buster .
docker container run -it --name caso1 -v ${PWD}/credentials:/root/.aws/credentials -v ${PWD}/Cloud9.yaml:/usr/src/Cloud9.yaml --rm -v ${PWD}/.vimrc:/root/.vimrc casopracticounir:1.0-buster bash
aws cloudformation create-stack --region us-east-1 --stack-name UnirAWSIDE --template-body file:///tmp/Cloud9.yaml
aws cloudformation delete-stack --stack-name UnirAWSIDE --region us-east-1

git clone git@github.com:mvicha/todo-list-serverless.git
# Read setup.sh from recently cloned repository
npm install -g serverless

Git branch  - Serverless Stage
feature     - serverless-dev (manually deployed using serverless cli)
develop     - dev (automatically deployed using git pull requests)
master      - prod (automatically deployed using git merge)


http://joshuaballoch.github.io/production-ready-aws-lambda/










aws codecommit create-repository --repository-name todo-list-serverless --repository-description "Aplicativo Backend en Python como ejemplo de migracion entre plataformas de desarrrollo procedente del Apartado A en Caso Practico 1 Experto Universitario en DevOps & Cloud." --tags Autor="Marcos Federico Villa"
{
    "repositoryMetadata": {
        "repositoryName": "todo-list-serverless",
        "cloneUrlSsh": "ssh://git-codecommit.us-east-1.amazonaws.com/v1/repos/todo-list-serverless",
        "lastModifiedDate": 1620653767.247,
        "repositoryDescription": "Aplicativo Backend en Python como ejemplo de migracion entre plataformas de desarrrollo procedente del Apartado A en Caso Practico 1 Experto Universitario en DevOps & Cloud.",
        "cloneUrlHttp": "https://git-codecommit.us-east-1.amazonaws.com/v1/repos/todo-list-serverless",
        "creationDate": 1620653767.247,
        "repositoryId": "77c87e44-XXXX-xxxx-XXXX-5853aebab478",
        "Arn": "arn:aws:codecommit:us-east-1:750489264097:todo-list-serverless",
        "accountId": "XXXXXXXXX"
    }
}


git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true

vocstartsoft:~/environment $ sam init
Which template source would you like to use?
        1 - AWS Quick Start Templates
        2 - Custom Template Location
Choice: 1
What package type would you like to use?
        1 - Zip (artifact is a zip uploaded to S3)
        2 - Image (artifact is an image uploaded to an ECR image repository)
Package type: 1

Which runtime would you like to use?
        1 - nodejs14.x
        2 - python3.8
        3 - ruby2.7
        4 - go1.x
        5 - java11
        6 - dotnetcore3.1
        7 - nodejs12.x
        8 - nodejs10.x
        9 - python3.7
        10 - python3.6
        11 - python2.7
        12 - ruby2.5
        13 - java8.al2
        14 - java8
        15 - dotnetcore2.1
Runtime: 2

Project name [sam-app]:

Cloning app templates from https://github.com/aws/aws-sam-cli-app-templates

AWS quick start application templates:
        1 - Hello World Example
        2 - EventBridge Hello World
        3 - EventBridge App from scratch (100+ Event Schemas)
        4 - Step Functions Sample App (Stock Trader)
        5 - Elastic File System Sample App
Template selection: 1

    -----------------------
    Generating application:
    -----------------------
    Name: sam-app
    Runtime: python3.8
    Dependency Manager: pip
    Application Template: hello-world
    Output Directory: .

    Next steps can be found in the README file at ./sam-app/README.md


docker network create aws
docker container run -d --network aws --name dynamo --rm -p 8000:8000 amazon/dynamodb-local
sam deploy --stack-name todo-list-serverless-sam --s3-bucket mvicha-todo-list-serverless-sam --capabilities CAPABILITY_IAM
aws cloudformation delete-stack --stack-name todo-list-serverless-sam

sam local start-api --port 8080 --debug --docker-network aws
aws dynamodb list-tables --endpoint-url http://localhost:8000

aws cloudformation describe-stacks --stack-name todo-list-serverless-staging --query 'Stacks[0].Outputs[?OutputKey==`todoListResourceApiId`].OutputValue' --output text
