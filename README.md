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

  * **create_repositories**

    Esta variable acepta los valores "**true**" o "**false**", y lo que nos permite es indicarle a terraform si queremos crear o no los repositorios en CodeCommit donde se guardará el código.

    En el caso de disponer de un repositorio se puede setear en "**false**" y setear las variables "**todo_list_repo**" "**python_env_repo**"


  * **python_env_repo**

    Esta variable se utiliza en el caso de que "**create_repositories**" sea "**false**" como parámetro del pipeline de "**Python-Env**"


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


  Para desplegar Jenkins seguiremos los pasos detallados a continuación:
  1. Configurar estado remoto:
  Esta versión de terraform nos permite guardar el estado del despliegue de forma remota. Si trabaja en múltiples máquinas a la vez (Cloud9 y local por ejemplo) puede experimentar conflictos de estado al momento de despliegue. Para que esto no suceda los pasos que se deben cumplimentar son los siguientes:
