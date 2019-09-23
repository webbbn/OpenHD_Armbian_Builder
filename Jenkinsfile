pipeline {
  agent any
  stages {
    stage('Nanopineo2') {
      steps {
        sh '''./scripts/build_image ArmbianBuild userpatches nanopineo2'''
      }
    }
    stage('Nanopineoplus2') {
      steps {
        sh '''./scripts/build_image ArmbianBuild userpatches nanopineoplus2'''
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
    stage('nanopineocore2') {
      steps {
        sh '''./scripts/build_image ArmbianBuild userpatches nanopineocore2'''
      }
    }
    stage('Nanopiduo2') {
      steps {
        sh '''./scripts/build_image ArmbianBuild userpatches nanopiduo2'''
      }
    }
    stage('Orange Pi Lite 2') {
      steps {
        sh '''./scripts/build_image ArmbianBuild userpatches orangepilite2'''
      }
    }
    stage('Orange Pi One Plus') {
      steps {
        sh '''./scripts/build_image ArmbianBuild userpatches orangepioneplus'''
      }
    }
    stage('Orange Pi Zero +2 H3') {
      steps {
        sh '''./scripts/build_image ArmbianBuild userpatches orangepizeroplus2-h3'''
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