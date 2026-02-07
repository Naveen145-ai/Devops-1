pipeline {
  agent any

  environment {
    DOCKER_USER = "yourdockername"
    AWS_DEFAULT_REGION = "ap-south-1"
  }

  stages {

    stage('Checkout Code') {
      steps {
        git credentialsId: 'github-creds',
            url: 'https://github.com/yourname/student-devops-project.git'
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
          docker build -t $DOCKER_USER/student-backend:latest backend/
          docker push $DOCKER_USER/student-backend:latest
        '''
      }
    }

    stage('Build & Push Frontend') {
      steps {
        sh '''
          docker build -t $DOCKER_USER/student-frontend:latest frontend/
          docker push $DOCKER_USER/student-frontend:latest
        '''
      }
    }

    stage('Terraform Init & Apply') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws-creds']]) {
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
        sh '''
          aws eks update-kubeconfig --region ap-south-1 --name student-eks
        '''
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
          kubectl get pods
          kubectl get svc
        '''
      }
    }
  }
}
