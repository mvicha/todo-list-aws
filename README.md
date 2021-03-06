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
  1. Comenzamos trabajando en una rama descendiente de develop, por ejemplo feature-A.
  2. Al terminar nuestro trabajo en feature-A haremos un pull request a develop
  3. Al aprobarse develop ejecutaremos el pipeline del entorno de desarrollo (Todo-List-Develop-Pipeline)
  4. Cuando estemos seguros que desarrollo está listo para promoverse haremos un pull request de develop a staging
  5. Ejecutaremos el pipeline de staging (Todo-List-Staging-Pipeline)
  6. Cuando estemos seguros que staging está listo para promoverse como estable haremos un pull request de staging a master
  7. Ejecutaremos el pipeline de producción (Todo-List-Production-Pipeline)

#### Ejecución de todos los trabajos a la vez.
  Existe un Job que se llama <b>Todo-List-Full-Pipeline</b>, este se ejecuta paso a paso desde desarrollo hasta producción.
  Cada ejecución exitosa del entorno anterior hará que los cambios del entorno sean incorporados en el siguiente nivel, y ejecutará el pipeline del nivel correspondiente, hasta llegar a producción

## Guía de procedmientos:
  Lo primero que debemos tener en cuenta es que este trabajo práctico tiene ciertos requerimientos. Para facilitar la instalación y despliegue de los mismos se han incluído algunas notas y se han mejorado algunos de los procesos que habían sido provistos para llevar a cabo dichos trabajos.

  Dividiremos estos pasos en despliegue en entorno local y despliegue en entorno cloud.

  Los pasos se detallan a continuación para ambos entornos:

### Despliegue en entorno local:
  Para desplegar en el entorno local utilizaremos el script ubicado en utils/runlocal.sh. Este script realiza las siguientes tareas:
  1. Crear el entorno local de desarrollo
  2. Ejecutar pruebas de código estático
  3. Inicializar SAM API
  4. Ejecutar pruebas de integración
  5. Construir el changeset de la aplicación y validarlo
  6. Desplegar el changeset a un entorno cloud desde el ambiente local
  7. Eliminar el despliegue de un entorno cloud
  8. Destruir el entorno de desarrollo local

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

    > **NOTA:** la ejecución de pruebas de integración permitiría testear entornos desplegados en la nube. Para ello en vez de incluir el parámetro "local", deberíamos incluir el parámetro del entorno que queremos verificar. Los valores soportados son: "local", "dev", "stg" y "prod"

  5) Creación del changeset
  ```bash
  utis/runlocal.sh build "dev"
  ```

    > **NOTA:** Como en el caso anterior, esta ejecución permite la creación de nuestro build para los distintos ambientes mediante el paso del entorno. Los valores sportados son: "**dev**", "**stg**" y "**prod**"

  6) Despliegue del entorno
  ```bash
  utils/runlocal.sh deploy "dev"
  ```

    > **NOTA:** Como en el caso anterior, esta ejecución permite el despliegue del entorno en el ambiente cloud mediante los parámetros provistos. Los valores sportados son: "**dev**", "**stg**" y "**prod**"

  7) Eliminación del despliegue de un ambiente cloud
  ```bash
  utils/runlocal.sh undeploy "dev"
  ```

    > **NOTA:** Como en el caso anterior, esta ejecución permite la eliminación del despliegue del ambiente cloud mediante los parámetros provistos. Los valores sportados son: "**dev**", "**stg**" y "**prod**"

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
  - Para configurar Cloud9 se proporciona un template en CloudFormation que incluye todo lo necesario para desplegar el entorno. El archivo README.md proporciona las instrucciones necesarias para desplegar el entorno:
      **URL:** git@github.com:mvicha/cloud9-env.git
      **BRANCH:** dev

    ```bash
    git clone git@github.com:mvicha/cloud9-env.git -b dev
    cd cloud9-env
    ```
    > Seguir las instrucciones de README.md

### Despliegue de la instancia de Jenkins:
  El entorno de Jenkins ha sido creado por completo desde cero, ya que en algún momento la imágen de Jenkins dejó de existir y para seguir trabajando tuve que crear una propia. Se disponen de varias variables que deben ser modificadas en el archivo * *variables.tf**. Se detallan a continuación:


  * **ecr_python_env_name**

    Esta variable guarda el nombre del ECR que crearemos para guardar las imágenes Docker de un entorno de Python y AWS para Jenkins


  * **codecommit_python_env**

    Esta variable guarda el nombre del repositorio para guardar el entorno de desarrollo


  * **codecommit_todo_list**

    Esta variable guarda el nombre del repositorio para guardar los sources de la app


  * **repo_unir_credentials**

    No es necesario modificar esta variable, y se recomienda no hacerlo. Esta variable define el repositorio que contiene el job de unir.


  * **repo_todo_list_pipelines**

    No es necesario modificar esta variable, y se recomienda no hacerlo. Esta variable define el repositorio que contiene los pipelines de Jenkins


  * **create_repositories**

    Esta variable acepta los valores "**true**" o "**false**", y lo que nos permite es indicarle a terraform si queremos crear o no los repositorios en CodeCommit donde se guardará el código.

    En el caso de disponer de un repositorio se puede setear en "**false**" y setear las variables "**todo_list_repo**" "**python_env_repo**"


  * **python_env_repo**

    Esta variable se utiliza en el caso de que "**create_repositories**" sea "**false**" como parámetro del pipeline de "**Python-Env**"


  * **python_env_image**

    Esta variable define una imagen preexistente de python-env. En caso de que el largo de que el valor contenga al menos un caracter se utilizará como imagen preexistente de Python-Env


  * **todo_list_repo**

    Esta variable se utiliza en el caso de que "**create_repositories**" sea "**false**" como parámetro de los pipeline  "**TODO-LIST...**"


  * **jenkinsHome**

    No es necesario modificar esta variable, y se recomienda no hacerlo. Esta variable se utiliza para definir el directorio HOME para la aplicación de Jenkins


  * **jenkinsVolume**

    No es necesario modificar esta variable, y se recomienda no hacerlo. Esta variable se utiliza para definir el directorio que se utilizará en el servidor como Volumen para compartir con el entorno Docker


  * **jenkinsHttp / jenkinsHttps**

    No es necesario modificar estas variable. Se utilizan para definir los puertos HTTP y HTTPS que queremos utilizar para conectarnos a Jenkins


  * **jenkinsUser / jenkinsPassword**

    Requerido setear estas variables. Serán utilizadas para configurar el usuario / contraseña del usuario con permisos de administrador de Jenkins


  * **jenkinsImage**

    Esta variable define la imagen de Jenkins que se utilizará para iniciar el contenedor con el servicio de Jenkins


#### Para desplegar Jenkins seguiremos los pasos detallados a continuación:
1) Configurar estado remoto:
  - Esta versión de terraform nos permite guardar el estado del despliegue de forma remota. Si trabaja en múltiples máquinas a la vez (Cloud9 y local por ejemplo) puede experimentar conflictos de estado al momento de despliegue. Para que esto no suceda los pasos que se deben cumplimentar son los siguientes:

    * Crear un bucket donde guardaremos el estado remoto
    ```bash
    aws s3api create-bucket --bucket <nombre-del-bucket> --region us-east-1
    ```

    * Utilizar el nombre del bucket creado en el archivo state.tf
    ```
    bucket  = "<nombre-del-bucket>"
    key     = "newjenkins.state"
    ```

2) Inicializar terraform:
  - La versión de terraform que utilizamos en este caso es Terraform v0.14.3. Si ejecuta otra version puede que se requiera realizar cambios para que el entorno se despliegue de la manera apropiada.

  - Edita el archivo de variables.tf dentro del directorio terraform. En el mismo encontrarás la variable ecr_python_env_name, que debe contener el nombre del ECR que se creará para guardar la imágen de docker

  - Si no se utilizara el default profile de AWS se debería exportar el valor a utilizar:
  ```bash
  export AWS_PROFILE=unir
  ```

  - Toma nota de la  dirección IP en tu máquina local, la necesitarás para ejecutar terraform. para conseguirla puedes ejecutar:
  ```bash
  export TF_VAR_myip=$(dig +short myip.opendns.com @resolver1.opendns.com)
  ```

  _ Ahora con esos datos puedes ejecutar terraform. Esto creará el entorno de Jenkins
  ```bash
  ./terraform init
  ./terraform plan -out=plan.out
  ./terraform apply plan.out
  ```

  Qué pasos realiza el proceso de Terraform:
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

  EL PROCESO DE TERRAFORM AUTOMÁTICAMENTE CONFIGURA LOS JOBS CON LOS PARÁMETROS REQUERIDOS GRACIAS A LA EJECUCIÓN DE **user-data**.
  El proceso en sí descarga un repositorio con los jobs y los parametriza, luego reinicia el servicio de Jenkins para que los Jobs queden configurados

### Configuración de Jenkins
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

  ```
  En caso de que no se utilizara el servicio de CodeCommit donde alojar el repositorio deberá utilizar la clave SSH asociada a GitHub y el usuario será git:
    ID: codecommit
    Username: git
    Private key (Enter directly): Github id_rsa key pair
  ```

  2) Ejecución de Jobs:
    - El primer Job que debemos ejecutar es el de ENABLE-UNIR-CREDENTIALS. Este Job ha sido modificado para solicitar ECR_URL como parámetro. Esto es para iniciar sesión. Este parámetro lo obenemos de la ejecución de terraform anterior bajo el output ecr_python_env_url. En el caso de haber perdido el output se puede recuperar:
  ```bash
  terraform output.
  ```

    - El siguiente Job que debemos ejecutar es el de Python-Env
    - Luego sólo nos queda ejecutar nuestro pipeline de desarrollo Todo-List-Dev-Pipeline o el que queramos ejecutar.

  **NOTA PARA IMPORTAR REPOSITORIOS:**

  Seguramente tengamos que imoprtar los repositorios de python-env y todo-list-aws en los reciéntemente creados por Teraform. Se entrega un script (utils/fix.sh) que facilitará la tarea. Este script recibe como parámetros el path del directorio del alumno y la nueva url del repositorio.

   A continuación un ejemplo:
  ```bash
  utils/fix.sh todo-list-aws git@github.com:mvicha/todo-list-aws.git ssh://git-codecommit.us-east-1.amazonaws.com/v1/repos/todo-list-aws-tf
  ```

## Terraform Output
  A continuación se detallan los valores obtenidos con el comando terraform output

  1. **codecommit_key_id** = ID de la clave SSH del usuario codecommit creado por terraform para utilizar los repositorios de CodeCommit
  2. **ecr_python_env_url** = ARN del servicio DKR de AWS creado para guardar las imágenes de Docker para Python-Env
  3. **jenkins_instance_id** = ID de la instancia Jenkins creada en AWS EC2
  4. **jenkins_instance_security_group_id** = ID del grupo de seguridad creado en AWS EC2 para la instancia de Jenkins
  5. **jenkins_public_ip** = Dirección IP pública de la instancia de Jenkins
  6. **jenkins_url** = URL por medio de la cual se puede acceder a Jenkins
  7. **key_pair_codecommit** = Clave SSH privada que se utilizará para acceder a los registros de CodeCommit. Esta clave debe ser ingresada en Jenkins para poder hacer uso de los repositorios privados de CodeCommit. (Copiar desde -----BEGIN RSA PRIVATE KEY----- hasta -----END RSA PRIVATE KEY----- inclusive)
  8. **key_pair_jenkins** = Clave SSH privada para acceder a la intancia de Jenkins
  9. **python_env_repo** = Repositorio donde se encuentra el código del entorno Ptyhon-Env
  10. **s3_bucket_development** = Bucket creado para guardar los archivos de CloudFormation para development
  11. **s3_bucket_production** = Bucket creado para guardar los archivos de CloudFormation para producción
  12. **s3_bucket_staging** = Bucket creado para guardar los archivos de CloudFormation para staging
  13. **ssh_connection** = Comando a ejecutar para conectar a la instancia de Jenkins via SSH
  14. **todo_list_env_repo** = Repositorio dónde se encuentra el código del entorno Todo-List

  ```
  Outputs:

  codecommit_key_id = "APKA25PFFL7QYIPFKQNI"
  ecr_python_env_url = ""
  jenkins_instance_id = "i-08213acc678e8faf9"
  jenkins_instance_security_group_id = "sg-03e5f65f77bc8368a"
  jenkins_public_ip = "54.90.163.247"
  jenkins_url = "http://54.90.163.247:80"
  key_pair_codecommit = <<EOT
  -----BEGIN RSA PRIVATE KEY-----
  MIIEowIBAAKCAQEAzv4cpAVrIYc10vEG3bGOseUdtIuHDbkUT+59zQ4/7vOhRFQ/
  36qgoHN4aI/Ldp6QIZt5riGCGLRIJ0iDtvcjWvy0W27Yb4N+nyN9B48CxIi7zd+4
  CAgD9dXyzBLWVxlnDcySbTcBBHMsfeidCQQbTUe6TBJoJLGBvdiqgCsDqAiB/wLF
  19c3JBWCjRsv7TKcDrNxJV212b80LX7SemNkR5OadxyW1lPlfLevNSwX6rmVU1g+
  TYQbrlbzsyL5sTF1rE18vCXVQTpAYwrKP2To/fEwFsBKaUqQ/NtGAzox1iFZsJh8
  3hZIDEp41MHGfzoX2OeiJkIcWfi2WDc7HdlhRwIDAQABAoIBAQC4MFyyA3RSEGvv
  ubRfX5lXaUZmmuXhazjM666b4js32Sk+kS2JTN7ECBw0BwiJFA2zKhM7xOtsKjgu
  ZJN4IzAdzdJ7rgYALOVmnICsUjCnS/i5+IJc+yzy+5+iwnxiYuNV3xzI/HH2ULpd
  i7j5BeN5gAMhoBt101Jc6cjGZgBJ6zZ13zLoVY7Ez4N/edXabsZMV3vH6gGvBXJb
  QcvPH5ujCTeamG3EwVqjxFf6S0b85tIFGWqUUtUjM73edEvjp40iXdsMZBcMff3V
  HyJdHCsZYdDJLpCPa1jJSRNmoQEvaH7IUOXtqKuZenwp7J8ieZaB/gVUl/wP44jH
  AFF0im7ZAoGBAOjJM4BBIBs3oLPy1CUFCe1JaI1Tce0c4kc5+LHWQAMj5TVsxOv7
  Jk/jXXhvb5AUETEPd4FZZNu6OREF+3kG5j23W5nUOUFpMSeonu0C4xJAsl113iEJ
  UDbwKlT8n/bAR+9RkdyVgbsw19cCiY2ac321ONpVfJzlQRWMlqlDP6FTAoGBAOOi
  brA7cePnXyRbgZwhCyh39ngY0TblMQcy/bJUiT7uZOJ5ssjvLE4h7q2Z/JA7JCLX
  BIeQ5KlZIGemv7VpzAQpc4mLzJZMs/13kJiOjfrnhiFEcQUg3t3Go6wqDp5Pgr4R
  Zea5ZUDdXsG09mj7xnGzz4yJjwod+yLMCPmJh729An94B0aG2w2y+vvhzVOVwwNb
  Vn6SYHRdzobeMwYIrHBVLi0BXxQqmVUn3BRWBR+BKteydEcqau2WXm8OWAdSYDxX
  ljOlHchn8dVmnYtUqihrQPC3QA9I+YRiz3MEXz4b/QkaXPTYyD4cRxMDyksiuIDU
  UJz/9xRJ0eu9MMB+hi5JAoGBAJ7YJi1MDfle5wFT6WmtlT+0FoVPrA6GeGPxrR7X
  5r3HVRbEnYGhhGUxQIBbx+ZNnrXBHSQMc8PIsdgif/xzyy3MTxdYOndXJvJkkL4k
  G+dN0Ec+ny9Y9KwFhQkKgBDwoudG9Li//mv5DbpWMOypZJzLQLVs+CezLB/oCQs4
  cURxAoGBALD8LpTMuvM+JbHmx/rDQtrWwhVEUNZl06WcvFswygJzzqeiwpb2fy1A
  ioVj4VF6wn2IC2icuhS1rX42Kvs7zD+AepvH/4xBly7a52AMMltcBkzjpYOFIlOX
  94eIEeZXrMll8YiP357UKFQraA2xt220MO/C41LCfGS68rFg/+lr
  -----END RSA PRIVATE KEY-----

  EOT
  key_pair_jenkins = <<EOT
  -----BEGIN RSA PRIVATE KEY-----
  MIIEpQIBAAKCAQEArZ29MNuKByjKgZlE5fRlwEf0ZHvW7ocarSV7CNFYVSd4a4e1
  iCmkk6AgPootJDkQZAltHV3Qi3KZMcLfhy7vpUoZ0AlAyzIB+PZUfeAtfo7MJx6A
  tgkNDYCznxz6qY9ghEh6iOtMQ0+hVrSQjl/VXapGR0hRYEpzuFqiJMd3L4EXPZJw
  2lnsqXI0o3yKP3f+xr/Ey310S8TmYK4Dc18j7re2CBnvXzBSjWyRXBATcqQaoy1w
  9VTvwWaCLEx2eQLNBPz30P0/ZvPqoKsX5RshxQIURp/yH4Ek8gwQ1MOG2jhcF8j/
  QqIAfXl8lcLDn/7o8StrUGd4iju2aPAMmLlsFwIDAQABAoIBAQCOzSy9EAaDBwEy
  AfBSuGgs9MJHGDlcLpI5kpeVVCO0vudkgtZErgPpTQ7YgezJW4pozfwK6IxM9rCc
  5m3XEjsZGE8M919tAq/uqCYs9wRUkX3IO2Wg1OcAkTitCjf+2aiIhdkL34X143yQ
  BarVAGxOQ2zU2t3cNsDiBOJTICGfVtGpacMDLuJ9LJlLHK11TaM0xDq5/hqc+h/N
  M80Ptb9Oh78paD6jz+T/+bqv4/ZVgW177NatA6Vxuheh2IeRJuXr9Wzr9tTxt016
  wi/mQXuvx6HHJJkV9Ev1a7WzVoxfYKxCO9H+rRdE73lDQLDOzL7k/cEAbP+iF+pQ
  UM0EeaJBAoGBAOZoK2m5xsTvdbrIh7RXanZ8WepL/B8PUexP8f85QqsEJ3sakVbJ
  KlGG/0LTvOLE+hkLqIw+Z1Az2UVFTyVOlPCvtKs9PwrLqo1AbbOQ5KHbjL/qLjHh
  u6gnpQIxXitIJ/t5Uxo7aCHxkTw4QRMy2Mk4879jvrB9NCb1Yl5RHpJ3AoGBAMDm
  rENMba+2OrJJEa3KetNd/ZWznPNovFZPbKTEiyPy6Xx0hRrwXiJE9uAbvRH2uHZn
  WPYgHUmp7M1f9SzWL/5tdVq30+n+5c77x25Ffl401GdeOTUGEA7kpcwCGyA+xiyt
  ttjQ4bnzKc1gb+ABVkpqS8UQuBx62Yoo6Bes0bthAoGBAMCw08XK2YIv5Zy9Qki/
  ZskKvEPnIkZzkIb6YR+aqrfNdJtOn8gd2udt6CLiY7CfHa4+gsovEkYP5qA5E7TW
  oFceCxG+2e9UXyFchaJMBfmbXH3QAqwy5bb+2NAZq3C1GsMEN0zT7AWfOmBLh5jf
  yE+Y8rjYWUzOmQQP6iGI4/GHAoGALeJw1W1HpgU9vwzcdK92OfLgkAxyZ//g1NL9
  r8/EnR955I2+36KPca1f3/0ZIz3BsQByS9FlxhDycAPESQ8FyYp14MdbVAy601pW
  nOdQ4M3GPHRQPUmc5j4DJhzWIPxtnVEQ7k/5cYbiyaSH2AvZX8gbD9wjPzsFpfSH
  CKKmHOECgYEA3/9SbC+7Lc3xUIeeD0w+li4E6gqFlbSPTtkKTwGWpllkx8tvmQsV
  u3ZjLxvPRINr+NCrZG5p9y7i4Srze/MyFP5pQxcfsH+LNdEm9VSBHi/id0Tg8zMQ
  xUWhAuYS65ejJcR6JET9V4Z3YYFs5qlGRuOBgYXdGRRTmeq7/tAq+r4=
  -----END RSA PRIVATE KEY-----

  EOT
  python_env_image = "mvilla/python-env:latest"
  python_env_repo = "ssh://git@gitlab.mvilla.org:8022/unir/python-env.git"
  s3_bucket_development = "es-unir-development-s3-42310-artifacts"
  s3_bucket_production = "es-unir-production-s3-42310-artifacts"
  s3_bucket_staging = "es-unir-staging-s3-42310-artifacts"
  ssh_connection = "ssh -i resources/jenkins/key.pem ec2-user@54.90.163.247"
  todo_list_env_repo = "git@github.com:mvicha/todo-list-aws.git
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
- terraform: en este directorio se almacenan los scripts necesarios para levantar la infraestructura necesaria  apartado B de la práctica. Para desplegar el contexto de Jenkins se ha de ejecutar el script de bash desde un terminal de linux (preferiblemente en la instancia de Cloud9). Durante el despliegue de la infraestructura, se solicitará la IP del equipo desde donde se va a conectar al servidor de Jenkins. Puedes consultarla previamente aquí: [cualesmiip.com](https://cualesmiip.com). Revisar la sección **Despliegue de la instancia de Jenkins** para conocer las variables que deben setearse antes de lanzar el script de configuración.
- todos: en este directorio se almacena el código fuente de las funciones lambda con las que se va a trabajar
- utils: Este directorio almacena algunas utilidades escenciales para el despliegue de los entornos local y cloud

