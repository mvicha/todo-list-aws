# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a
Changelog](https://keepchangelog.com/en/1.0.0/),
and this project adheres to [Semantic
Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2021-05-10
### Added
- Versión inicial de código
- aws s3api create-bucket --bucket mvicha-todo-list-serverless-sam
- sam template
- lambda functions
- lambda class

## [1.0.1] - 2021-06-08
- table check and table creation if doesn't exist
- Use Jenkinsfile from repository
- Create CodeCommit, ECR resources in AWS
- Create CodeCommit user, SSH Key-Pair and associate it to CodeCommit policies and resources
- Run unit tests, static code checks and coverage
- Create integration testing to run after deployment
- Define environment dependencies
- Create a unique Docker container to do deployments
- Create a script to export existing repos to newly created repos
- Clean directory before and after pipeline execution
- Error handling so to not leave any Docker containers/networks after successfull/failure execution
- Create new Jenkins instance based on a different AMI using user-data configuration
- Parametrize Jenkins instance with several different options
- Create Docker containers and Docker networks based on a variable value so multiple instances of the pipeline may be running at once
- Create pipelines from external GitHub sources
- Enable API logs
- Add ability to create repositories or not based on a terraform variable
- Add run local script to easily deploy solution locally
- Parametrize Jenkinsfile to work with Docker in Docker
- Fix documentation
- Add the ability to use external images/repos

