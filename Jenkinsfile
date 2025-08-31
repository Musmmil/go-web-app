pipeline {
    agent any
    environment {
        IMAGE_NAME = 'muzammil22/go-web-app'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        EC2_HOST = '18.236.246.206'
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
                    sh 'sonar-scanner -Dsonar.projectKey=my-golang-app -Dsonar.sources=. -Dsonar.host.url=http://35.87.201.88:9000 -Dsonar.token=$SONAR_TOKEN'
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
// New stage for monitoring validation
        stage('Validate Deployment') {
            when {
        expression { currentBuild.currentResult == 'SUCCESS' } // Run if the build is successful so far
    }
            steps {
                script {
                    // Wait for app to stabilize (adjust sleep as needed)
                    sleep 30

                    // Query Prometheus for metrics (example: check CPU usage)
                    def prometheusUrl = "http://18.236.246.206:9090/api/v1/query"
                    def cpuQuery = 'rate(container_cpu_usage_seconds_total{container="your-app-container"}[5m])'
                    def cpuResponse = sh(script: "curl -s '${prometheusUrl}?query=${cpuQuery}' | jq -r '.data.result[0].value[1]'", returnStdout: true).trim()
                    def cpuUsage = cpuResponse.toFloat()
                    if (cpuUsage > 0.8) { // Example threshold: 80% CPU
                        error "Deployment failed: CPU usage too high (${cpuUsage}"
                    }

                    // Query Loki for error logs
                    def lokiUrl = "http://18.236.246.206:3100/loki/api/v1/query"
                    def logQuery = '{container="your-app-container"} |~ "ERROR"'
                    def logResponse = sh(script: "curl -s '${lokiUrl}?query=${logQuery}&limit=10' | jq -r '.data.result | length'", returnStdout: true).trim()
                    def errorCount = logResponse.toInteger()
                    if (errorCount > 0) {
                        error "Deployment failed: Found ${errorCount} error logs"
                    }

                    echo "Deployment validated successfully: CPU usage=${cpuUsage}, Errors=${errorCount}"
                }
            }
        }
    }
}
    
