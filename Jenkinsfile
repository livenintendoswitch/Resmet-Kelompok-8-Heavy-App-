pipeline {
    agent any

    triggers {
        githubPush()
    }

    stages {
        stage('Checkout Source') {
            steps {
                checkout scm
            }
        }

        stage('Assume Role & Deploy to Fargate') {
            steps {
                withCredentials([file(credentialsId: 'aws-deployment-config', variable: 'INFRA_CONFIG')]) {
                    sh """
                    echo "⚙️ Loading infrastructure configuration from secret file..."
                    set -a
                    . \$INFRA_CONFIG
                    set +a

                    # Extract the AWS Account ID from the Role ARN (even though we aren't assuming it anymore, we still need the ID for the ECR URL)
                    AWS_ACCOUNT_ID=\$(echo "\${AWS_ROLE_ARN}" | cut -d':' -f5)
                    REGISTRY_URL="\${AWS_ACCOUNT_ID}.dkr.ecr.\${AWS_REGION}.amazonaws.com"

                    echo "🚀 Logging into Amazon ECR..."
                    aws ecr get-login-password --region \${AWS_REGION} | docker login --username AWS --password-stdin \${REGISTRY_URL}

                    echo "🔨 Packaging and Pushing Docker Image..."
                    IMAGE_URI="\${REGISTRY_URL}/\${ECR_REPOSITORY}:\${GIT_COMMIT}"
                    docker build -t \${IMAGE_URI} .
                    docker push \${IMAGE_URI}

                    echo "📋 Injecting new Image URI into task-definition.json..."
                    jq "(.containerDefinitions[0]).image = \\"\${IMAGE_URI}\\"" ./task-definition.json > updated-task-def.json

                    echo "🚀 Registering Task Revision & Updating Fargate Service..."
                    NEW_TASK_ARN=\$(aws ecs register-task-definition --cli-input-json file://updated-task-def.json --region \${AWS_REGION} --query 'taskDefinition.taskDefinitionArn' --output text)
                    
                    aws ecs update-service --cluster \${ECS_CLUSTER} --service \${ECS_SERVICE} --task-definition \${NEW_TASK_ARN} --region \${AWS_REGION}
                    
                    echo "✅ Deployment successful!"
                    """
                }
            }
        }
    }

    post {
        always {
            sh "rm -f updated-task-def.json"
        }
    }
}