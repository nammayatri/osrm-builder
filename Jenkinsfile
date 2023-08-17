pipeline {
    agent { label 'nixos' }
    triggers {
        cron('0 13 * * 4')
    }
    stages {
        stage ('Nix Build') {
            steps {
                nixCI()
            }
        }
        stage ('Docker image') {
            when { branch 'main' }
            steps {
                dockerPush "dockerImage", "ghcr.io"
            }
        }
    }
}
