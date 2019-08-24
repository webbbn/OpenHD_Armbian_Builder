pipeline {
  agent any
  stages {
    stage('Nanopiduo2') {
      steps {
        sh '''./scripts/build_image ArmbianBuild userpatches nanopiduo2'''
      }
    }
    stage('Nanopineo4') {
      steps {
        sh '''./scripts/build_image ArmbianBuild userpatches nanopineo4'''
      }
    }
    stage('Nanopifire3') {
      steps {
        sh '''./scripts/build_image ArmbianBuild userpatches nanopifire3'''
      }
    }
    stage('Archive and cleanup') {
      steps {
        archiveArtifacts(artifacts: 'ArmbianBuild/output/images/Armbian*img.gz', onlyIfSuccessful: true)
        archiveArtifacts(artifacts: 'ArmbianBuild/output/debs/*.deb', onlyIfSuccessful: true)
        sh '''sudo rm -rf ArmbianBuild/output'''
      }
    }
  }
}