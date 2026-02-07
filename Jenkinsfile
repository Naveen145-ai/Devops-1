pipeline {
  agent any

  environment {
    DOCKER_USER = "naveen656"
    AWS_DEFAULT_REGION = "us-east-1"
    CLUSTER_NAME = "student-eks"
  }

  stages {

    stage('Checkout Code') {
      steps {
        git credentialsId: 'github-creds',
            url: 'https://github.com/Naveen145-ai/Devops-1.git'
      }
    }

    stage('Docker Login') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-creds',
          usernameVariable: 'DOCKER_USERNAME',
          passwordVariable: 'DOCKER_PASSWORD'
        )]) {
          sh '''
            echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
          '''
        }
      }
    }

    stage('Build & Push Backend') {
      steps {
        sh '''
          docker build -t $DOCKER_USER/student-backend:latest backend
          docker push $DOCKER_USER/student-backend:latest
        '''
      }
    }

    stage('Build & Push Frontend') {
      steps {
        sh '''
          docker build -t $DOCKER_USER/student-frontend:latest frontend
          docker push $DOCKER_USER/student-frontend:latest
        '''
      }
    }

    stage('Terraform Init & Apply') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws-access']]) {
          sh '''
            cd terraform
            terraform init
            terraform apply -auto-approve
          '''
        }
      }
    }

    stage('Update kubeconfig') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws-access']]) {
          sh '''
            aws eks update-kubeconfig \
              --region $AWS_DEFAULT_REGION \
              --name $CLUSTER_NAME
          '''
        }
      }
    }

    stage('Deploy to EKS') {
      steps {
        sh '''
          kubectl apply -f k8s/
        '''
      }
    }

    stage('Verify Pods') {
      steps {
        sh '''
          kubectl get nodes
          kubectl get pods -A
          kubectl get svc
        '''
      }
    }
  }
}
