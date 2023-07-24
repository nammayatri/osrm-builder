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
                dockerPush "dockerImage", "ghcr.io"
            }
        }
        stage ('Cleanup') {
            steps {
                sh """
                    set -x
                    nix-store --query --referrers ${env.FLAKE_OUTPUTS} | xargs nix store delete
                    nix store delete ${env.FLAKE_OUTPUTS}
                """
            }
        }
    }
}
