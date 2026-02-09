pipeline {
  agent any

  environment {
    DOCKER_USER = "naveen656"
    AWS_REGION = "us-east-1"
    EKS_CLUSTER_NAME = "student-eks-new"
    AWS_ACCOUNT_ID = "312320185931"
  }

  stages {
    stage('Checkout') {
      steps {
        echo "Checking out code..."
        checkout scm
      }
    }

    stage('Docker Login') {
      steps {
        script {
          echo "Logging into Docker Hub..."
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
    }

    stage('Build Backend Image') {
      steps {
        echo "Building backend Docker image..."
        sh '''
          docker build -t $DOCKER_USER/student-backend:latest ./backend
          docker tag $DOCKER_USER/student-backend:latest $DOCKER_USER/student-backend:v1.0
        '''
      }
    }

    stage('Build Frontend Image') {
      steps {
        echo "Building frontend Docker image..."
        sh '''
          docker build -t $DOCKER_USER/student-frontend:latest ./frontend
          docker tag $DOCKER_USER/student-frontend:latest $DOCKER_USER/student-frontend:v1.0
        '''
      }
    }

    stage('Push Images to Docker Hub') {
      steps {
        echo "Pushing images to Docker Hub..."
        sh '''
          docker push $DOCKER_USER/student-backend:latest
          docker push $DOCKER_USER/student-backend:v1.0
          docker push $DOCKER_USER/student-frontend:latest
          docker push $DOCKER_USER/student-frontend:v1.0
        '''
      }
    }

    stage('Create EKS Cluster') {
      steps {
        echo "Creating EKS cluster using Terraform..."
        withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY', credentialsId: 'aws-access')]) {
          sh '''
            cd terraform
            terraform init
            terraform plan -out=tfplan
            terraform apply tfplan
            cd ..
          '''
        }
      }
    }

    stage('Configure kubectl') {
      steps {
        echo "Configuring kubectl to access EKS cluster..."
        withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY', credentialsId: 'aws-access')]) {
          sh '''
            aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME
          '''
        }
      }
    }

    stage('Deploy to EKS') {
      steps {
        echo "Deploying application to EKS cluster..."
        sh '''
          kubectl apply -f k8s/backend-deployment.yaml
          kubectl apply -f k8s/frontend-deployment.yaml
          
          echo "Waiting for pods to be ready..."
          kubectl rollout status deployment/student-backend -n student-app --timeout=5m
          kubectl rollout status deployment/student-frontend -n student-app --timeout=5m
          
          echo "Getting service details..."
          kubectl get svc -n student-app
        '''
      }
    }
  }

  post {
    always {
      echo "Pipeline execution completed"
      sh 'docker logout || true'
    }
    success {
      echo "Deployment to EKS successful!"
      sh '''
        echo "Backend Service: kubectl get svc backend-service -n student-app"
        echo "Frontend Service: kubectl get svc frontend-service -n student-app"
        echo "\nFrontend External IP (might take 1-2 minutes to appear):"
        kubectl get svc frontend-service -n student-app --no-headers | awk '{print $4}'
      '''
    }
    failure {
      echo "Pipeline failed! Check logs above."
    }
  }
}
