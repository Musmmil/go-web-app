pipeline {
    agent any
    environment {
        IMAGE_NAME = 'muzammil22/go-web-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        EC2_HOST = '35.166.200.7 '
        DOCKER_REGISTRY = 'https://index.docker.io/v1/'
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
        sh 'gitleaks detect --source=. -v --exit-code=1'  // --exit-code=1 fails build if secrets found
    }
}
        stage('SonarQube Analysis') {
    environment {
        SONAR_TOKEN = credentials('sonar_token')  // Store token as Jenkins credential
    }
    steps {
        withSonarQubeEnv('SonarQube') {  // Configure SonarQube server in Jenkins > Manage Jenkins > Configure System > SonarQube servers
            sh 'sonar-scanner -Dsonar.projectKey=my-golang-app -Dsonar.sources=. -Dsonar.host.url=http://35.87.120.24:9000/ -Dsonar.login=$SONAR_TOKEN'
        }
    }
}
        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build("${IMAGE_NAME}:${IMAGE_TAG}")
                }
            }
        }
       stage('Trivy Scan') {
            steps {
                sh "trivy image --exit-code 1 --no-progress --severity HIGH,CRITICAL ${IMAGE_NAME}:${IMAGE_TAG}"
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
