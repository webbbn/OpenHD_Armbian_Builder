pipeline {
  agent any
  stages {
    stage('Nanopineo2') {
      steps {
        sh './scripts/build_image ArmbianBuild userpatches nanopineo2'
        sh './scripts/archive_artifacts'
        sh 'sudo rm -rf ArmbianBuild/output'
      }
    }
    stage('Nanopineoplus2') {
      steps {
        sh './scripts/build_image ArmbianBuild userpatches nanopineoplus2'
        sh './scripts/archive_artifacts'
        sh 'sudo rm -rf ArmbianBuild/output'
      }
    }
    stage('Nanopineo4') {
      steps {
        sh './scripts/build_image ArmbianBuild userpatches nanopineo4'
        sh './scripts/archive_artifacts'
        sh 'sudo rm -rf ArmbianBuild/output'
      }
    }
    stage('Nanopifire3') {
      steps {
        sh './scripts/build_image ArmbianBuild userpatches nanopifire3'
        sh './scripts/archive_artifacts'
        sh 'sudo rm -rf ArmbianBuild/output'
      }
    }
    stage('nanopineocore2') {
      steps {
        sh './scripts/build_image ArmbianBuild userpatches nanopineocore2'
        sh './scripts/archive_artifacts'
        sh 'sudo rm -rf ArmbianBuild/output'
      }
    }
    stage('Nanopiduo2') {
      steps {
        sh './scripts/build_image ArmbianBuild userpatches nanopiduo2'
        sh './scripts/archive_artifacts'
        sh 'sudo rm -rf ArmbianBuild/output'
      }
    }
    stage('Orange Pi Zero +2 H3') {
      steps {
        sh './scripts/build_image ArmbianBuild userpatches orangepizeroplus2-h3'
        sh './scripts/archive_artifacts'
        sh 'sudo rm -rf ArmbianBuild/output'
      }
    }
  }
}