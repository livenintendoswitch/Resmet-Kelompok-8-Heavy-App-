pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        ACR_NAME              = 'benchmarkacrkel8'
        RG_NAME               = 'benchmark-apps-rg'
        APP_NAME              = 'heavy-app-service'
    }

    stages {
        stage('Checkout Source') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push to ACR') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'ACR_CREDENTIALS', passwordVariable: 'ACR_PASSWORD', usernameVariable: 'ACR_USER')]) {
                    sh """
                    echo "🚀 Logging into Azure Container Registry..."
                    docker login \${ACR_NAME}.azurecr.io -u \${ACR_USER} -p \${ACR_PASSWORD}

                    echo "🔨 Packaging and Pushing Docker Image..."
                    IMAGE_URI="\${ACR_NAME}.azurecr.io/\${APP_NAME}:\${GIT_COMMIT}"
                    docker build -t \${IMAGE_URI} .
                    docker push \${IMAGE_URI}
                    """
                }
            }
        }

        stage('Manual Deployment Step') {
            steps {
                // Stripped out the failing Service Principal login
                echo '========================================================================'
                echo '✅ BUILD & PUSH SUCCESSFUL!'
                echo '⚠️ AUTOMATED DEPLOYMENT BLOCKED BY AZURE DIRECTORY PERMISSIONS'
                echo 'Run this exact command on your local Mac terminal to deploy the new code:'
                echo '========================================================================'
                
echo "az containerapp update --name ${APP_NAME} --resource-group ${RG_NAME} --image ${ACR_NAME}.azurecr.io/${APP_NAME}:${GIT_COMMIT}"
            }
        }
    }
}