#cloud-config
bootcmd:
  - mkdir /var/lib/docker
  - while [ ! -b $(readlink -f /dev/xvdc) ]; do echo "Waiting for xvdc device"; sleep 5; done
  - blkid $(readlink -f /dev/xvdc) || mkfs -t ext4 $(readlink -f /dev/xvdc)
  - e2label $(readlink -f /dev/xvdc) docker
  - grep -q ^LABEL=docker /etc/fstab || echo 'LABEL=docker /var/lib/docker ext4 defaults,nofail 0 2' >> /etc/fstab
  - grep -q "$(readlink -f /dev/xvdc) /var/lib/docker " /proc/mounts | mount /var/lib/docker

  - mkdir ${jenkinsVolume}
  - while [ ! -b $(readlink -f /dev/xvdd) ]; do echo "Waiting for xvdd device"; sleep 5; done
  - blkid $(readlink -f /dev/xvdd) || mkfs -t ext4 $(readlink -f /dev/xvdd)
  - e2label $(readlink -f /dev/xvdd) jenkins
  - grep -q ^LABEL=jenkins /etc/fstab || echo 'LABEL=jenkins ${jenkinsVolume} ext4 defaults,nofail 0 2' >> /etc/fstab
  - grep -q "$(readlink -f /dev/xvdd) ${jenkinsVolume} " /proc/mounts | mount ${jenkinsVolume}

repo_update: true
groups:
  - jenkins

users:
  - default
  - name: jenkins
    gecos: Jenkins User
    primary_group: jenkins
    groups: docker

system_info:
  default_user:
    groups: [docker]

disable_root: true
ssh_pwauth:   false

packages:
  - git

runcmd:
  - [ sh, -c, "amazon-linux-extras install -y docker" ]
  - mkdir -p ${jenkinsVolume}/jobs ${jenkinsVolume}/.aws ${jenkinsVolume}/.docker
  - update-alternatives --install /usr/bin/python python /usr/bin/python3.7 1

  # Unir Credentials
  - git clone ${repoUnirCredentials} ${jenkinsVolume}/jobs/ENABLE-UNIR-CREDENTIALS
  - sed -i "s/AWSAccountId/${accountId}/g" ${jenkinsVolume}/jobs/ENABLE-UNIR-CREDENTIALS/config.xml

  # Python-Env
  - git clone ${repoTodoListPipelines} -b feature-gitplugin /tmp/TODO-LIST
  - sed -i 's@dkr_python_env_url@${pythonEcr}@g' /tmp/TODO-LIST/Python-Env/config.xml
  - sed -i 's@codecommit_python_env_url@${pythonRepo}@g' /tmp/TODO-LIST/Python-Env/config.xml
  - mv /tmp/TODO-LIST/Python-Env ${jenkinsVolume}/jobs/Python-Env

  # Pipeline-Staging
  - sed -i 's@dkr_python_env_url@${pythonImage}@g' /tmp/TODO-LIST/PIPELINE-FULL-STAGING/config.xml
  - sed -i 's@codecommit_todo_list_repo@${todoRepo}@g' /tmp/TODO-LIST/PIPELINE-FULL-STAGING/config.xml
  - sed -i 's@staging_bucket_name@${stgBucket}@g' /tmp/TODO-LIST/PIPELINE-FULL-STAGING/config.xml
  - sed -i 's@production_bucket_name@${prodBucket}@g' /tmp/TODO-LIST/PIPELINE-FULL-STAGING/config.xml
  - mv /tmp/TODO-LIST/PIPELINE-FULL-STAGING ${jenkinsVolume}/jobs/PIPELINE-FULL-STAGING

  # Pipleine-Prod
  - sed -i 's@dkr_python_env_url@${pythonImage}@g' /tmp/TODO-LIST/PIPELINE-FULL-PRODUCTION/config.xml
  - sed -i 's@codecommit_todo_list_repo@${todoRepo}@g' /tmp/TODO-LIST/PIPELINE-FULL-PRODUCTION/config.xml
  - sed -i 's@staging_bucket_name@${stgBucket}@g' /tmp/TODO-LIST/PIPELINE-FULL-PRODUCTION/config.xml
  - sed -i 's@production_bucket_name@${prodBucket}@g' /tmp/TODO-LIST/PIPELINE-FULL-PRODUCTION/config.xml
  - mv /tmp/TODO-LIST/PIPELINE-FULL-PRODUCTION ${jenkinsVolume}/jobs/PIPELINE-FULL-PRODUCTION

  # Pipeline-CD
  - sed -i 's@dkr_python_env_url@${pythonImage}@g' /tmp/TODO-LIST/PIPELINE-FULL-CD/config.xml
  - sed -i 's@codecommit_todo_list_repo@${todoRepo}@g' /tmp/TODO-LIST/PIPELINE-FULL-CD/config.xml
  - mv /tmp/TODO-LIST/PIPELINE-FULL-CD ${jenkinsVolume}/jobs/PIPELINE-FULL-CD

  - chmod 777 ${jenkinsVolume}
  - chown -R 1001:1000 ${jenkinsVolume}
  - chmod -R 775 ${jenkinsVolume}/jobs

  - mkdir -p /etc/systemd/system/docker.service.d
  - echo -en "[Service]\nExecStart=\nExecStart=/usr/bin/dockerd -H unix:///var/run/docker.sock -H tcp://0.0.0.0" | tee /etc/systemd/system/docker.service.d/override.conf
  - systemctl daemon-reload
  - systemctl start docker

  # Jenkins
  - docker network create jenkins-network
  - docker image pull mvilla/jenkinsawsdocker:latest
  - docker container run -d --name jenkins --hostname jenkins -p ${jenkinsHttp}:8080 -p ${jenkinsHttps}:8443 --network jenkins-network --volume ${jenkinsVolume}:${jenkinsHome} -e JENKINS_USERNAME="${jenkinsUser}" -e JENKINS_PASSWORD="${jenkinsPassword}" -e JENKINS_HOME=${jenkinsHome} -e DOCKER_HOST=172.17.0.1:2375 --restart unless-stopped ${jenkinsImage}

  - echo "The setup has been completed" > ${jenkinsVolume}/custom_setup
