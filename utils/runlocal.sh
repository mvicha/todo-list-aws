#!/bin/bash

action=${1}

if [[ -z "${AWS_PROFILE}" ]]; then
  awsProfile=""
else
  awsProfile="-e AWS_PROFILE=${AWS_PROFILE}"
fi


function help {
    echo "Usage: ${0} <action>"
    echo -en "\nActions:"
    echo -en "\n\tcreate:\t\t\tCrea la estructura de test"
    echo -en "\n\trun-static-tests:\tEjecuta tests de código estáticos"
    echo -en "\n\trun-integration-tests\tEjecuta tests de integración"
    echo -en "\n\trun-api:\t\tInicia la api"
    echo -en "\n\tdestroy:\t\tElimina la estructura de test"
    echo -en "\n\tbuild:\t\t\tConstruir el changeset de la aplicación desde el ambiente local"
    echo -en "\n\tdeploy:\t\t\tDesplegar la aplicación desde el ambiente local"
    echo -en "\n\tundeploy:\t\tElimna deploy de cloudformation\n"
    echo -en "\nOpciones para run-integration-tests, build, deploy y undeploy"
    echo -en "\n\t${0} run-integration-tests <environmentType>"
    echo -en "\n\t${0} build <environmentType>"
    echo -en "\n\t${0} deploy <environmentType> <s3bucket>"
    echo -en "\n\t${0} undeploy <environmentType>\n\n"

    echo "Pasos a seguir:"
    echo -en "\t1) Crear la estructura: ${0} create"
    echo -en "\n\t2) Ejecutar tests estáticos: ${0} run-static-tests"
    echo -en "\n\t3) Iniciar la API: ${0} run-api"
    echo -en "\n\t4) Ejecutar tests de integración: ${0} run-integration-tests <environmentType>"
    echo -en "\n\t5) Terminar la ejecución: ${0} destroy\n\n"

    echo -en "NOTA: Si utilizas un AWS profile distinto a default exporta la variable de entorno\n"
    echo -en "AWS_PROFILE con el nombre del profile: ej: export AWS_PROFILE=unir\n\n"
}

function cleanUp {
    docker container exec -i -w /opt/todo-list-aws -u root python-env-timeInSeconds rm -rf .aws-sam/*
}

function validateEnv {
    env=${1}
    arrEnvironments=("dev" "stg" "prod")
    for environment in "${arrEnvironments[@]}"; do
        if [[ "${env}" == "${environment}" ]]; then
            return 0
        fi
    done
    return 1
}

case ${action} in
    -h|--help)
        help
        ;;
    create)
        if [[ -z "$(docker network ls --format '{{ .Name }}' | egrep aws | tr -d '\n')" ]]; then
            echo "Creating aws network"
            docker network create aws
        else
            echo "Docker network already exists"
        fi
        
        ddbres=$(docker container ls -a --format '{{.Names}} {{.Status}}' | egrep 'dynamodb-timeInSeconds')
        if [[ -z "${ddbres}" ]]; then
            echo "Initiating DynamoDB container"
            docker container run -d --network aws --name dynamodb-timeInSeconds --rm amazon/dynamodb-local
        else
            read -a ddbstatus <<< "${ddbres}"
            if [[ "${ddbstatus[1]}" != "Up" ]]; then
                echo "Starting DynamoDB container ${ddbstatus}"
                docker container start dynamodb-timeInSeconds
            else
                echo "DynamoDB container already running"
            fi
        fi
        
        penvres=$(docker container ls -a --format '{{.Names}} {{.Status}}' | egrep 'python-env-timeInSeconds')
        if [[ -z "${penvres}" ]]; then
            echo "Initiating python-env container"
            docker container run --name python-env-timeInSeconds --link dynamodb-timeInSeconds:dynamodb --network aws -di -v /var/run/docker.sock:/var/run/docker.sock -v ${HOME}/.aws:/home/builduser/.aws -v ${PWD}:${PWD} 750489264097.dkr.ecr.us-east-1.amazonaws.com/mvicha-ecr-python-env:latest
            echo "Linkin DynamoDB ${PWD} path to /opt/todo-list/aws"
            docker container exec -u root python-env-timeInSeconds ln -sf ${PWD} /opt/todo-list-aws
        else
            read -a penvstatus <<< "${penvres}"
            if [[ "${penvstatus[1]}" != "Up" ]]; then
                echo "Starting python-env container"
                docker container start python-env-timeInSeconds
            else
                echo "python-env container already running"
            fi
        fi
        ;;
    run-static-tests)
        docker container exec -i python-env-timeInSeconds /opt/todo-list-aws/tests/run_tests.sh
        docker container exec -i python-env-timeInSeconds /opt/todo-list-aws/tests/run_unittest.sh
        ;;
    run-api)
        docker container exec -it -w /opt/todo-list-aws -u root -e HOME=/home/builduser python-env-timeInSeconds bash -c "/home/builduser/.local/bin/sam local start-api -n env.json --region us-east-1 --host 0.0.0.0 --port 8080 --debug --docker-network aws --docker-volume-basedir ${PWD}"
        ;;
    run-integration-tests)
        if [[ -n "${2}" ]]; then
            environmentType=${2}
            if [[ "${environment}" != "local" ]]; then
              result="$(validateEnv ${environmentType})"
            else
              result=0
            fi

            if [[ ${?} -eq 0 ]]; then
                docker container exec -i ${awsProfile} -w /opt/todo-list-aws python-env-timeInSeconds /opt/todo-list-aws/tests/run_integration.sh ${environmentType}
            else
                help
            fi
        else
            help
        fi
        ;;
    destroy)
        cleanUp
        docker container rm -f python-env-timeInSeconds
        docker container rm -f dynamodb-timeInSeconds
        docker network rm aws
        ;;
    build)
        if [[ -n "${2}" ]]; then
            environmentType=${2}
            result="$(validateEnv ${environmentType})"
            if [[ ${?} -eq 0 ]]; then
                echo "Build parameters:"
                echo "Env: ${environmentType}"
                cleanUp
                docker container exec -i -w /opt/todo-list-aws python-env-timeInSeconds /home/builduser/.local/bin/sam build --region us-east-1 --debug --docker-network aws --parameter-overrides EnvironmentType=${environmentType}
                docker container exec -i -w /opt/todo-list-aws python-env-timeInSeconds /home/builduser/.local/bin/aws cloudformation validate-template --template-body file://.aws-sam/build/template.yaml
            else
                help
            fi
        else
            help
        fi
        ;;
    deploy)
        if [[ -n "${2}" && -n "${3}" ]]; then
            environmentType=${2}
            result="$(validateEnv ${environmentType})"
            if [[ ${?} -eq 0 ]]; then
                s3bucket=${3}
                echo "Deploy parameters:"
                echo "Env: ${environmentType}"
                echo "Bucket: ${s3bucket}"
                docker container exec -i ${awsProfile} -w /opt/todo-list-aws python-env-timeInSeconds /home/builduser/.local/bin/sam deploy --region us-east-1 --debug --force-upload --stack-name todo-list-aws-${environmentType} --debug --s3-bucket ${s3bucket} --capabilities CAPABILITY_NAMED_IAM --parameter-overrides EnvironmentType=${environmentType}
    
                restApiId=$(docker container exec -i ${awsProfile} python-env-timeInSeconds /home/builduser/.local/bin/aws cloudformation describe-stacks --stack-name todo-list-aws-${environmentType} --query 'Stacks[0].Outputs[?OutputKey==`todoListResourceApiId`].OutputValue' --output text | tr -d '\n')
                docker container exec -i ${awsProfile} python-env-timeInSeconds /home/builduser/.local/bin/aws apigateway update-stage \
                    --rest-api-id ${restApiId} \
                    --stage-name Prod \
                    --patch-operations \
                        op=replace,path=/*/*/logging/dataTrace,value=true \
                        op=replace,path=/*/*/logging/loglevel,value=Info \
                        op=replace,path=/*/*/metrics/enabled,value=true
            else
                help
            fi
        else
            help
        fi
        ;;
    undeploy)
        if [[ -n "${2}" ]]; then
            environmentType=${2}
            result="$(validateEnv ${environmentType})"
            if [[ ${?} -eq 0 ]]; then
                echo "Undeploy parameters:"
                echo "Env: ${environmentType}"
                cleanUp
                docker container exec -i ${awsProfile} -w /opt/todo-list-aws python-env-timeInSeconds /home/builduser/.local/bin/aws cloudformation delete-stack --stack-name todo-list-aws-${environmentType}
                echo "Deleting Table:"
                docker container exec -i ${awsProfile} -w /opt/todo-list-aws python-env-timeInSeconds /home/builduser/.local/bin/aws dynamodb delete-table --table-name todoTable-${environmentType}
            else
                help
            fi
        fi
        ;;
    *)
        help
        ;;
esac
