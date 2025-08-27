pipeline {
    agent any
    environment {
        IMAGE_NAME = muzammil22/go-web-app // Replace with your Docker Hub username/repo
        IMAGE_TAG = "${env.BUILD_NUMBER}" // Uses Jenkins build number for versioning
        EC2_HOST = '44.251.25.120' // Replace with your EC2 public IP or DNS
        DOCKER_REGISTRY = https://hub.docker.com/repository/docker/muzammil22/go-web-app/general
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', 
                    url: 'https://github.com/Musmmil/go-web-app.git' // Replace with your repo
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${IMAGE_NAME}:${IMAGE_TAG}")
                }
            }
        }
        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry(DOCKER_REGISTRY, 'dockerhub-creds') {
                        dockerImage.push()
                        dockerImage.push('latest')
                    }
                }
            }
        }
        stage('Deploy to EC2') {
            steps {
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ec2-user@${EC2_HOST} \
                        'docker pull ${IMAGE_NAME}:${IMAGE_TAG} && \
                         docker stop go-app-container || true && \
                         docker rm go-app-container || true && \
                         docker run -d --name go-app-container -p 8080:8080 ${IMAGE_NAME}:${IMAGE_TAG}'
                    """
                }
            }
        }
    }
    post {
        always {
            script {
                // Clean up Docker images locally to save space
                sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true"
            }
        }
        success {
            echo 'Pipeline completed successfully! Application deployed to EC2.'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}
