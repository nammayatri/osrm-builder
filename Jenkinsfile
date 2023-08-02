pipeline {
    agent { label 'nixos' }
    triggers {
        cron('0 15 * * 5')
    }
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
                dockerPush "dockerImage", "ghcr.io"
            }
        }
    }
}
