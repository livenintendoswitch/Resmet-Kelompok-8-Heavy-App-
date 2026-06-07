pipeline {
    agent any
    environment {
        ACR_NAME = 'benchmarkacrkel8'
        APP_NAME = 'heavy-app-service'
        IMAGE_TAG = "${env.BUILD_ID}"
    }
    stages {
        stage('Build & Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'ACR_CREDENTIALS', passwordVariable: 'ACR_PASSWORD', usernameVariable: 'ACR_USER')]) {
                    // Log directly into the registry
                    sh 'docker login ${ACR_NAME}.azurecr.io -u $ACR_USER -p $ACR_PASSWORD'
                    
                    // Build the monolithic container
                    sh 'docker build -t ${ACR_NAME}.azurecr.io/${APP_NAME}:${IMAGE_TAG} .'
                    
                    // Push to Azure
                    sh 'docker push ${ACR_NAME}.azurecr.io/${APP_NAME}:${IMAGE_TAG}'
                }
            }
        }
        stage('Manual Deployment Step') {
            steps {
                echo '========================================================================'
                echo 'BUILD SUCCESSFUL! AUTOMATED DEPLOYMENT PAUSED (AWAITING SERVICE PRINCIPAL)'
                echo 'Run this exact command on your local Mac terminal to deploy the new code:'
                echo '========================================================================'
                echo "az containerapp update --name heavy-app-service --resource-group benchmark-apps-rg --image benchmarkacrkel8.azurecr.io/heavy-app-service:${IMAGE_TAG}"
            }
        }
    }
}