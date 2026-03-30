pipeline {
    // Specify that this pipeline should run on an agent labeled 'windows'
    // Make sure your Windows agent in Jenkins has this label.
    //agent { label 'windows' }
    agent any

    environment {
        ACR_REGISTRY_NAME = 'mcplculator'
        ACR_REGISTRY_URL = "${ACR_REGISTRY_NAME}.azurecr.io"
        IMAGE_NAME = 'calculator-app'
        IMAGE_TAG = "build-${BUILD_NUMBER}"
        AKS_CLUSTER_NAME = 'aks-mcp'
        AKS_RESOURCE_GROUP = 'aks-mcp'
        // Use Windows-style path for the kubeconfig
        KUBECONFIG_PATH = "${env.WORKSPACE}\\kubeconfig_build_${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // This command remains the same, but requires the Docker Pipeline plugin
                    // and Docker running on the Windows agent.
                    docker.build("${ACR_REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}", '.')
                }
            }
        }

        stage('Login to ACR using Managed Identity') {
            steps {
                // Use 'bat' for Windows batch commands
                bat 'az login --identity'
                bat "az acr login --name ${ACR_REGISTRY_NAME}"
            }
        }

        stage('Push Docker Image') {
            steps {
                bat "docker push ${ACR_REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Deploy to AKS using Managed Identity') {
            steps {
                script {
                    // Generate the kubeconfig file using 'bat'
                    bat "az aks get-credentials --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_CLUSTER_NAME} --file ${KUBECONFIG_PATH}"
                    
                    // Replace the Linux 'sed' command with a Windows PowerShell command
                    powershell "(Get-Content .\\kubernetes\\deployment.yaml) | ForEach-Object { $_ -replace '__IMAGE__', '${ACR_REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}' } | Set-Content .\\kubernetes\\deployment.yaml"

                    // Use 'bat' and set the KUBECONFIG environment variable for the commands
                    bat "set KUBECONFIG=${KUBECONFIG_PATH} && kubectl apply -f kubernetes\\deployment.yaml"
                    bat "set KUBECONFIG=${KUBECONFIG_PATH} && kubectl apply -f kubernetes\\service.yaml"
                }
            }
        }
    }

    post {
        always {
            // Clean up using 'bat'
            bat "del /F /Q ${KUBECONFIG_PATH}"
            bat "docker logout ${ACR_REGISTRY_URL}"
        }
    }
}


