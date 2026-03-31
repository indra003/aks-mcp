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
        // Service Principal environment variables
        AZURE_TENANT_ID = credentials('azure-tenant-id')
        AZURE_SUBSCRIPTION_ID = credentials('azure-subscription-id')

        ACR_USERNAME='dd0a7370-c013-4057-b2a3-b7a3ed893908'
        ACR_PASSWORD='5BS8Q~ZshoKb9yODnUvPJDCDBtswLJ-pGSIMXaQl'
        AZURE_SUBSCRIPTION_ID='8999e91c-2bbd-4df2-b54d-171fe6db06c5'
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

        stage('Login to ACR using Service Principal') {
            steps {
                // Use Jenkins credentials for Service Principal
                withCredentials([usernamePassword(credentialsId: 'azure-service-principal', usernameVariable: 'AZURE_CLIENT_ID', passwordVariable: 'AZURE_CLIENT_SECRET')]) {
                    // Login to Azure using Service Principal
                    //bat 'az login --service-principal -u %AZURE_CLIENT_ID% -p %AZURE_CLIENT_SECRET% --tenant %AZURE_TENANT_ID%'
                    bat "az login --service-principal -u ${env.ACR_USERNAME} -p ${env.ACR_PASSWORD} --tenant yourTenantID"

                    //bat 'az account set --subscription %AZURE_SUBSCRIPTION_ID%'
                    bat "az account set --subscription ${env.AZURE_SUBSCRIPTION_ID}"
                    
                    // Login to ACR using Service Principal credentials
                    //bat "az acr login --name ${ACR_REGISTRY_NAME} --username %AZURE_CLIENT_ID% --password %AZURE_CLIENT_SECRET%"
                    bat "az acr login --name ${ACR_REGISTRY_NAME} -u ${env.ACR_USERNAME} -p ${env.ACR_PASSWORD}"
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                bat "docker push ${ACR_REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Deploy to AKS using Service Principal') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'azure-service-principal', usernameVariable: 'AZURE_CLIENT_ID', passwordVariable: 'AZURE_CLIENT_SECRET')]) {
                        // Login to Azure using Service Principal
                        bat 'az login --service-principal -u %AZURE_CLIENT_ID% -p %AZURE_CLIENT_SECRET% --tenant %AZURE_TENANT_ID%'
                        bat 'az account set --subscription %AZURE_SUBSCRIPTION_ID%'
                        
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
    }

    post {
        always {
            // Clean up using 'bat'
            bat "del /F /Q ${KUBECONFIG_PATH}"
            bat "docker logout ${ACR_REGISTRY_URL}"
        }
    }
}


