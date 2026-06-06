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
                // 🔒 Securely pull the infrastructure map from the Jenkins vault
                // FIX: Changed variable from AWS_CONFIG_FILE to INFRA_CONFIG
                withCredentials([file(credentialsId: 'aws-deployment-config', variable: 'INFRA_CONFIG')]) {
                    sh """
                    echo "⚙️ Loading infrastructure configuration from secret file..."
                    
                    # 🛠️ Universal POSIX dot (.) operator replacing the 'source' command
                    set -a
                    # FIX: Changed variable to match the line above
                    . \$INFRA_CONFIG
                    set +a

                    echo "🔐 Assuming AWS Target Role: \${AWS_ROLE_ARN}..."
                    
                    # 1. Exchange your Secret File's Role ARN for temporary security credentials
                    CREDENTIALS=\$(aws sts assume-role \
                        --role-arn "\${AWS_ROLE_ARN}" \
                        --role-session-name "JenkinsFargateDeploymentSession" \
                        --query "Credentials" \
                        --output json)

                    # 2. Export tokens to the local execution runtime environment
                    export AWS_ACCESS_KEY_ID=\$(echo "\$CREDENTIALS" | jq -r '.AccessKeyId')
                    export AWS_SECRET_ACCESS_KEY=\$(echo "\$CREDENTIALS" | jq -r '.SecretAccessKey')
                    export AWS_SESSION_TOKEN=\$(echo "\$CREDENTIALS" | jq -r '.SessionToken')

                    # 3. Extract the AWS Account ID straight from your configuration's Role ARN string
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
                    
                    echo "✅ Deployment successful under assumed secret configuration!"
                    """
                }
            }
        }
    }

    post {
        always {
            // Ensure scratchpads are wiped clean so consecutive benchmarking runs don't conflict
            sh "rm -f updated-task-def.json"
        }
    }
}