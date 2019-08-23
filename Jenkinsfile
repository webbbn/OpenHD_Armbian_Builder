pipeline {
  agent any
  stages {
    stage('Nanopiduo2') {
      steps {
        sh '''./scripts/build_image ArmbianBuild userpatches nanopiduo2
'''
      }
    }
  }
}