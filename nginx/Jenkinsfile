pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps {
        git url: 'https://github.com/ofirgaash1/nginx-aws-pipeline.git', branch: 'master'
      }
    }

    stage('Build and Push Docker Image with Ansible') {
      steps {
        dir('ansible') {
          sh 'ansible-playbook deploy.yml'
        }
      }
    }
  }
}
