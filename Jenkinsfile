pipeline {
  agent any

  environment {
    ECR_REPO = '314525640319.dkr.ecr.il-central-1.amazonaws.com/ofir/nginx'
    IMAGE_TAG = "${BUILD_NUMBER}"
    FULL_IMAGE = "${ECR_REPO}:${IMAGE_TAG}"
  }

  stages {
    stage('Checkout') {
      steps {
        git url: 'https://github.com/ofirgaash1/nginx-aws-pipeline.git', branch: 'master'
      }
    }
    stage('Check index.html') {
      steps {
        sh 'cat nginx/index.html'
      }
    }

    stage('Build and Push Docker Image with Ansible') {
      steps {
        dir('ansible') {
          sh "ansible-playbook deploy.yml -e build_number=${IMAGE_TAG}"
        }
      }
    }

    stage('Import ECS and ALB (one-time only)') {
      steps {
        dir('docker/jenkins/scripts') {
          sh './terraform-import.sh'
        }
      }
    }

    stage('Terraform Init') {
      steps {
        dir('nginx/terraform') {
          sh '''
            terraform init \
              -backend-config="bucket=imtech-2025" \
              -backend-config="key=Ofir/terraform.tfstate" \
              -backend-config="region=il-central-1" \
              -backend-config="encrypt=true"
          '''
        }
      }
    }
    
    stage('Deploy to ECS with Terraform') {
      steps {
        dir('nginx/terraform') {
          sh """
            terraform apply -input=false -auto-approve \
              -var="container_image=${FULL_IMAGE}"
          """
        }
      }
    }


    
  }
}

