pipeline {
    agent { label 'nixos' }
    stages {
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
