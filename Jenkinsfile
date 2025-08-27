pipeline {
    agent any
    environment {
        IMAGE_NAME = 'muzammil22/go-web-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        EC2_HOST = '44.251.25.120'
        DOCKER_REGISTRY = 'https://index.docker.io/v1/'
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Musmmil/go-web-app.git'
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
                    docker.withRegistry("${DOCKER_REGISTRY}", 'dockerhub-creds') {
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
