pipeline {
  agent any

  environment {
    ECR_REPO = '314525640319.dkr.ecr.us-east-1.amazonaws.com/ofir/first-repo'
    IMAGE_TAG = "${BUILD_NUMBER}"
    FULL_IMAGE = "${ECR_REPO}:${IMAGE_TAG}"
  }

  stages {
    stage('Checkout') {
      steps {
        git url: 'https://github.com/ofirgaash1/nginx-aws-pipeline.git', branch: 'master'
      }
    }

    stage('Build and Push Docker Image with Ansible') {
      steps {
        dir('ansible') {
          sh "ansible-playbook deploy.yml -e build_number=${IMAGE_TAG}"
        }
      }
    }

    stage('Import ECS (one-time only)') {
      steps {
        dir('terraform') {
          sh 'terraform-import.sh'
        }
      }
    }

    stage('Deploy to ECS with Terraform') {
      steps {
        dir('nginx/terraform') {
          sh """
            terraform init
            terraform apply -auto-approve \
              -var="container_image=${FULL_IMAGE}"
          """
        }
      }
    }
  }
}

