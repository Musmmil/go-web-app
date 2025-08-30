pipeline {
    agent any
    environment {
        IMAGE_NAME = 'muzammil22/go-web-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        EC2_HOST = '35.166.200.7'
        DOCKER_REGISTRY = 'https://index.docker.io/v1/'
        SONAR_TOKEN = credentials('sonar_token')
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Musmmil/go-web-app.git'
            }
        }
        stage('GitLeaks Scan') {
            steps {
                sh 'gitleaks detect --source=. -v --exit-code=1'
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'sonar-scanner -Dsonar.projectKey=my-golang-app -Dsonar.sources=. -Dsonar.host.url=http://35.87.120.24:9000 -Dsonar.token=$SONAR_TOKEN'
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    def dockerImage = docker.build("${IMAGE_NAME}:${IMAGE_TAG}")
                    env.DOCKER_IMAGE = dockerImage.id // Store for later use
                }
            }
        }
        stage('Trivy Scan') {
            steps {
                sh "trivy image --exit-code 1 --no-progress --severity HIGH,CRITICAL --ignorefile .trivyignore ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
        stage('Push to Docker Hub') {
            steps {
                script {
                    docker.withRegistry("${DOCKER_REGISTRY}", 'dockerhub-creds') {
                        docker.image("${IMAGE_NAME}:${IMAGE_TAG}").push()
                        docker.image("${IMAGE_NAME}:${IMAGE_TAG}").push('latest')
                    }
                }
            }
        }
        stage('Deploy to EC2') {
            steps {
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ec2-user@${EC2_HOST} \
                        "docker pull ${IMAGE_NAME}:${IMAGE_TAG} && \
                         docker stop go-app-container || true && \
                         docker rm go-app-container || true && \
                         docker run -d --name go-app-container -p 8080:8080 ${IMAGE_NAME}:${IMAGE_TAG}"
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
