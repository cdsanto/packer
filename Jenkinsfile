pipeline {
    agent any

    stages {
        stage('Checkout Git') {
            steps {
                echo 'Descargando el repositorio de Git...'
                git branch: 'main', url: 'https://github.com/cdsanto/packer.git'
                sh 'chmod 644 ubuntu-free-tier.pkr.hcl'
                sh 'ls -lt'
            }
        }

        stage('Packer Build') {
            steps {
                echo 'Iniciando el proceso de construcción con Packer...'
                
                // Usamos con AWS Steps pasando tus credenciales y la región deseada
                withAWS(credentials: 'aws_terraform', region: 'us-east-1') {
                    script {
                        sh 'echo "La región configurada en Jenkins es: $AWS_DEFAULT_REGION"'
                        // Inicializa los plugins necesarios de Packer
                        sh 'packer init ubuntu-free-tier.pkr.hcl'
                        
                        // Valida que el archivo HCL no tenga errores
                        sh 'packer validate ubuntu-free-tier.pkr.hcl'
                        
                        // Construye la AMI en AWS
                        sh 'packer build ubuntu-free-tier.pkr.hcl'
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo 'Limpiando el espacio de trabajo...'
            cleanWs()
        }
        success {
            echo '¡AMI generada con éxito en AWS!'
        }
        failure {
            echo 'Hubo un error en la ejecución del pipeline. Revisa los logs.'
        }
    }
}