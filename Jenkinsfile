pipeline {
  agent any

  environment {
    DOCKER_USER = "naveen656"
    EC2_HOST = "your-ec2-ip-or-hostname"
    EC2_USER = "ec2-user"
  }

  stages {

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

    stage('Deploy to EC2') {
      steps {
        withCredentials([sshUserPrivateKey(
          credentialsId: 'ec2-ssh-key',
          keyFileVariable: 'SSH_KEY'
        )]) {
          sh '''
            ssh -i $SSH_KEY -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST << 'EOF'
              docker pull $DOCKER_USER/student-backend:latest
              docker pull $DOCKER_USER/student-frontend:latest
              docker stop backend-container || true
              docker stop frontend-container || true
              docker rm backend-container || true
              docker rm frontend-container || true
              docker run -d --name backend-container -p 5000:5000 $DOCKER_USER/student-backend:latest
              docker run -d --name frontend-container -p 80:80 $DOCKER_USER/student-frontend:latest
            EOF
          '''
        }
      }
    }
  }
}
