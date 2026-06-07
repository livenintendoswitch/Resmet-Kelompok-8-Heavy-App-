pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        // Your Azure Environment Variables
        ACR_NAME              = 'benchmarkacrkel8'
        RG_NAME               = 'benchmark-apps-rg'
        APP_NAME              = 'heavy-app-service'
        
        // Azure Service Principal Details (Required for the final deploy command)
        AZURE_SUBSCRIPTION_ID = 'your-subscription-id' 
        AZURE_TENANT_ID       = 'your-tenant-id'       
        AZURE_CLIENT_ID       = 'your-sp-app-id'       
    }

    stages {
        stage('Checkout Source') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push to ACR') {
            steps {
                // Using the ACR admin credentials we set up earlier to bypass Entra ID for the build
                withCredentials([usernamePassword(credentialsId: 'ACR_CREDENTIALS', passwordVariable: 'ACR_PASSWORD', usernameVariable: 'ACR_USER')]) {
                    sh """
                    echo "🚀 Logging into Azure Container Registry..."
                    docker login \${ACR_NAME}.azurecr.io -u \${ACR_USER} -p \${ACR_PASSWORD}

                    echo "🔨 Packaging and Pushing Docker Image..."
                    # Using GIT_COMMIT just like your AWS pipeline for precise version tracking
                    IMAGE_URI="\${ACR_NAME}.azurecr.io/\${APP_NAME}:\${GIT_COMMIT}"
                    docker build -t \${IMAGE_URI} .
                    docker push \${IMAGE_URI}
                    """
                }
            }
        }

        stage('Deploy to Azure Container Apps') {
            steps {
                // This replaces your Fargate task-definition update. 
                // Azure Container Apps handles the revision update in a single command.
                withCredentials([string(credentialsId: 'AZURE_SP_PASSWORD', variable: 'SP_PASSWORD')]) {
                    sh """
                    echo "🔐 Authenticating Jenkins with Azure..."
                    az login --service-principal -u \${AZURE_CLIENT_ID} -p \${SP_PASSWORD} --tenant \${AZURE_TENANT_ID}
                    az account set --subscription \${AZURE_SUBSCRIPTION_ID}

                    echo "🚀 Updating Container App Service Revision..."
                    IMAGE_URI="\${ACR_NAME}.azurecr.io/\${APP_NAME}:\${GIT_COMMIT}"
                    
                    az containerapp update \\
                        --name \${APP_NAME} \\
                        --resource-group \${RG_NAME} \\
                        --image \${IMAGE_URI}

                    echo "✅ Deployment successful!"
                    """
                }
            }
        }
    }
}