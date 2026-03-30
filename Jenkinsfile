// pipeline {
//     agent any

//     environment {
//         // Define your Azure Container Registry (ACR) and AKS cluster details
//         ACR_REGISTRY_NAME = 'yourACRRegistryName'
//         ACR_REGISTRY_URL = "${ACR_REGISTRY_NAME}.azurecr.io"
//         IMAGE_NAME = 'calculator-app'
//         IMAGE_TAG = "build-${BUILD_NUMBER}"
//         AKS_CLUSTER_NAME = 'yourAKSClusterName'
//         AKS_RESOURCE_GROUP = 'yourAKSResourceGroup'
//     }

//     stages {
//         stage('Checkout') {
//             steps {
//                 // Checkout the source code from your repository
//                 checkout scm
//             }
//         }

//         stage('Build Docker Image') {
//             steps {
//                 script {
//                     // Build the Docker image for your calculator app
//                     docker.build("${ACR_REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}", '.')
//                 }
//             }
//         }

//         stage('Login to ACR') {
//             steps {
//                 // Login to your Azure Container Registry
//                 // Assumes you have a credential with ID 'acr-credentials' in Jenkins
//                 withCredentials([usernamePassword(credentialsId: 'acr-credentials', usernameVariable: 'ACR_USERNAME', passwordVariable: 'ACR_PASSWORD')]) {
//                     sh "echo ${ACR_PASSWORD} | docker login ${ACR_REGISTRY_URL} -u ${ACR_USERNAME} --password-stdin"
//                 }
//             }
//         }

//         stage('Push Docker Image') {
//             steps {
//                 // Push the Docker image to your ACR
//                 sh "docker push ${ACR_REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
//             }
//         }

//         stage('Deploy to AKS') {
//             steps {
//                 script {
//                     // Deploy the application to your AKS cluster
//                     // Assumes you have a kubeconfig file credential with ID 'aks-kubeconfig' in Jenkins
//                     withCredentials([file(credentialsId: 'aks-kubeconfig', variable: 'KUBECONFIG_FILE')]) {
//                         sh "sed -i 's|__IMAGE__|${ACR_REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}|g' kubernetes/deployment.yaml"
//                         sh "KUBECONFIG=${KUBECONFIG_FILE} kubectl apply -f kubernetes/deployment.yaml"
//                         sh "KUBECONFIG=${KUBECONFIG_FILE} kubectl apply -f kubernetes/service.yaml"
//                     }
//                 }
//             }
//         }
//     }

//     post {
//         always {
//             // Logout from ACR
//             sh "docker logout ${ACR_REGISTRY_URL}"
//         }
//     }
// }
pipeline {
    agent any

    environment {
        // Define your Azure Container Registry (ACR) and AKS cluster details
        ACR_REGISTRY_NAME = 'yourACRRegistryName'
        ACR_REGISTRY_URL = "${ACR_REGISTRY_NAME}.azurecr.io"
        IMAGE_NAME = 'calculator-app'
        IMAGE_TAG = "build-${BUILD_NUMBER}"
        AKS_CLUSTER_NAME = 'yourAKSClusterName'
        AKS_RESOURCE_GROUP = 'yourAKSResourceGroup'
        // Define a temporary path for the kubeconfig file
        KUBECONFIG_PATH = "${env.WORKSPACE}/kubeconfig_build_${BUILD_NUMBER}"
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
                    docker.build("${ACR_REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}", '.')
                }
            }
        }

        stage('Login to ACR using Managed Identity') {
            steps {
                // Use Azure CLI to login to ACR with the VM's Managed Identity.
                // No username or password needed.
                sh "az login --identity"
                sh "az acr login --name ${ACR_REGISTRY_NAME}"
            }
        }

        stage('Push Docker Image') {
            steps {
                sh "docker push ${ACR_REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Deploy to AKS using Managed Identity') {
            steps {
                script {
                    // This block will now dynamically generate the kubeconfig for this build
                    // It authenticates using the Managed Identity.
                    sh "az aks get-credentials --resource-group ${AKS_RESOURCE_GROUP} --name ${AKS_CLUSTER_NAME} --file ${KUBECONFIG_PATH}"
                    
                    // The rest of the deployment uses the generated kubeconfig
                    sh "sed -i 's|__IMAGE__|${ACR_REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}|g' kubernetes/deployment.yaml"
                    sh "KUBECONFIG=${KUBECONFIG_PATH} kubectl apply -f kubernetes/deployment.yaml"
                    sh "KUBECONFIG=${KUBECONFIG_PATH} kubectl apply -f kubernetes/service.yaml"
                }
            }
        }
    }

    post {
        always {
            // Clean up the temporary kubeconfig file and logout
            sh "rm -f ${KUBECONFIG_PATH}"
            sh "docker logout ${ACR_REGISTRY_URL}"
        }
    }
}
