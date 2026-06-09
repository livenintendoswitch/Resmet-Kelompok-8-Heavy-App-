pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        ACR_NAME = 'benchmarkacrkel8'
        RG_NAME  = 'benchmark-apps-rg'
        APP_NAME = 'heavy-app-service'
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
                    
                    # Force Jenkins to explicitly map the environment variable
                    REGISTRY="${env.ACR_NAME}.azurecr.io"
                    CLEAN_USER=\$(echo "\$ACR_USER" | tr -d '\\r\\n ')
                    
                    # CRITICAL FIX: Options (-u, --password-stdin) MUST come BEFORE the registry URL!
                    printf "%s" "\$ACR_PASSWORD" | docker login -u "\$CLEAN_USER" --password-stdin "\$REGISTRY"

                    echo "🔨 Packaging and Pushing Docker Image..."
                    COMMIT_HASH=\$(git rev-parse HEAD | tr -d '\\r\\n ')
                    IMAGE_URI="\${REGISTRY}/${env.APP_NAME}:\${COMMIT_HASH}"
                    
                    docker build -t "\$IMAGE_URI" .
                    docker push "\$IMAGE_URI"
                    """
                }
            }
        }

        stage('Automated Deployment') {
            steps {
                sh """
                echo "🚀 Triggering Azure Container App Update..."
                
                COMMIT_HASH=\$(git rev-parse HEAD | tr -d '\\r\\n ')
                REGISTRY="${env.ACR_NAME}.azurecr.io"
                
                az containerapp update \\
                    --name "${env.APP_NAME}" \\
                    --resource-group "${env.RG_NAME}" \\
                    --image "\${REGISTRY}/${env.APP_NAME}:\${COMMIT_HASH}"
                    
                echo "✅ DEPLOYMENT COMPLETE!"
                """
            }
        }
    }
}