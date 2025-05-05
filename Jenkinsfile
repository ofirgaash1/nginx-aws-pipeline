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
          sh "ansible-playbook deploy.yml -e build_number=${BUILD_NUMBER}"
        }
      }
    }

    stage('Deploy to ECS with Terraform') {
      steps {
        dir('terraform') {
          sh """
            terraform init
            terraform apply -auto-approve \
              -var="container_image=314525640319.dkr.ecr.us-east-1.amazonaws.com/ofir/first-repo:${BUILD_NUMBER}"
          """
        }
      }
    }
  }
}

