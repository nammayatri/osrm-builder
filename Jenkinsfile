pipeline {
    agent { label 'nixos' }
    stages {
        stage ('Download data') {
            steps {
                sh 'nix run .#fetch'
                sh 'git add -N southern-zone-latest.*'  // For Nix to recognize
            }
        }
        stage ('Nix Build All') {
            steps {
                nixBuildAll system: env.SYSTEM
            }
        }
        stage ('Docker image') {
            when { branch 'main' }
            steps {
                sh 'git rm -rf southern-zone-latest.*'
                dockerPush "dockerImage", "ghcr.io"
            }
        }
    }
}
