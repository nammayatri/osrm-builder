pipeline {
    agent { label 'nixos' }
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
