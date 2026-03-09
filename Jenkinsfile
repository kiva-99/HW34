pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "kiva99/hw34-flask"
        DOCKER_TAG   = "build-${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "=== Получаем код из Git ==="
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "=== Собираем Docker образ ==="
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
            }
        }

        stage('Parallel Tests') {
            parallel {

                stage('Test - pytest') {
                    steps {
                        echo "=== Запускаем юнит-тесты ==="
                        sh """
                            docker run --rm ${DOCKER_IMAGE}:${DOCKER_TAG} \
                            python -m pytest app/test_app.py -v
                        """
                    }
                }

                stage('Test - flake8 lint') {
                    steps {
                        echo "=== Проверяем стиль кода ==="
                        sh """
                            docker run --rm ${DOCKER_IMAGE}:${DOCKER_TAG} \
                            python -m flake8 app/app.py --max-line-length=88
                        """
                    }
                }

                stage('Test - safety check') {
                    steps {
                        echo "=== Проверяем уязвимости зависимостей ==="
                        sh """
                            docker run --rm ${DOCKER_IMAGE}:${DOCKER_TAG} \
                            pip list
                        """
                    }
                }

            }
        }

        stage('Push to DockerHub') {
            steps {
                echo "=== Пушим образ в DockerHub ==="
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh "echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin"
                    sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    sh "docker push ${DOCKER_IMAGE}:latest"
                }
            }
        }

        stage('Deploy') {
            steps {
                echo "=== Запускаем контейнер ==="
                sh "docker stop hw34-app || true"
                sh "docker rm hw34-app || true"
                sh """
                    docker run -d \
                        --name hw34-app \
                        -p 5000:5000 \
                        ${DOCKER_IMAGE}:${DOCKER_TAG}
                """
                echo "=== Приложение доступно на http://localhost:5000 ==="
            }
        }

    }

    post {
        success {
            echo "=== ✅ Pipeline выполнен успешно! ==="
        }
        failure {
            echo "=== ❌ Pipeline завершился с ошибкой ==="
        }
        always {
            echo "=== Очистка: удаляем старые образы ==="
            sh "docker image prune -f"
        }
    }
}