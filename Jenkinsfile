pipeline {
    agent { label 'docker-builder' }

    environment {
        DOCKER_IMAGE = "kirilliva/hw34-flask"
        DOCKER_TAG   = "build-${BUILD_NUMBER}"
        DEPLOY_REPO  = "https://github.com/kiva-99/HW34-deploy.git"
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
                sh 'docker build -t $DOCKER_IMAGE:$DOCKER_TAG .'
                sh 'docker tag $DOCKER_IMAGE:$DOCKER_TAG $DOCKER_IMAGE:latest'
            }
        }

        stage('Parallel Tests') {
            parallel {

                stage('Test - pytest') {
                    steps {
                        echo "=== Запускаем юнит-тесты ==="
                        sh 'docker run --rm $DOCKER_IMAGE:$DOCKER_TAG python -m pytest test_app.py -v'
                    }
                }

                stage('Test - flake8 lint') {
                    steps {
                        echo "=== Проверяем стиль кода ==="
                        sh 'docker run --rm $DOCKER_IMAGE:$DOCKER_TAG python -m flake8 app.py --max-line-length=88'
                    }
                }

                stage('Test - pip audit') {
                    steps {
                        echo "=== Список зависимостей ==="
                        sh 'docker run --rm $DOCKER_IMAGE:$DOCKER_TAG pip list --format=columns'
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
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                    sh 'docker push $DOCKER_IMAGE:$DOCKER_TAG'
                    sh 'docker push $DOCKER_IMAGE:latest'
                    sh 'docker logout'
                }
            }
        }

        stage('Update Deploy Config (GitOps)') {
    steps {
        echo "=== GitOps: обновляем конфиг деплоя ==="
        withCredentials([usernamePassword(
            credentialsId: 'github-credentials',
            usernameVariable: 'GIT_USER',
            passwordVariable: 'GIT_PASS'
        )]) {
            sh """
                rm -rf hw34-deploy-repo
                git clone https://github.com/kiva-99/HW34-deploy.git hw34-deploy-repo
                cd hw34-deploy-repo

                sed -i 's|tag:.*|tag: ${DOCKER_TAG}|' deploy-config.yml
                sed -i 's|build_number:.*|build_number: "${BUILD_NUMBER}"|' deploy-config.yml
                sed -i 's|timestamp:.*|timestamp: "'\$(date -u +%Y-%m-%dT%H:%M:%SZ)'"|' deploy-config.yml
                sed -i 's|updated_by:.*|updated_by: jenkins|' deploy-config.yml

                git config user.email "jenkins@hw34.local"
                git config user.name "Jenkins CI"
                git add deploy-config.yml
                git diff --staged --quiet || git commit -m "deploy: update image to ${DOCKER_TAG} [build ${BUILD_NUMBER}]"
                git push https://\$GIT_USER:\$GIT_PASS@github.com/kiva-99/HW34-deploy.git main
            """
        }
        echo "=== ✅ Deploy config обновлён ==="
    }
}

    }

    post {
        success {
            echo "✅ Pipeline выполнен успешно на агенте: ${env.NODE_NAME}"
        }
        failure {
            echo "❌ Pipeline завершился с ошибкой на агенте: ${env.NODE_NAME}"
        }
        always {
            sh 'docker image prune -f'
            sh 'rm -rf hw34-deploy-repo'
        }
    }
}