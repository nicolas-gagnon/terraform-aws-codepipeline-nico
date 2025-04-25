
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket        = "eks-pipeline-artifacts-nico"
  force_destroy = true
}

resource "aws_codepipeline" "eks_pipeline" {
  name     = "eks-deploy-pipeline"
  role_arn = "arn:aws:iam::247084108338:role/terraformpipe-codebuild-execution"

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = "arn:aws:codeconnections:us-east-1:247084108338:connection/fb47638b-04c0-4139-8adc-792e380ab021"
        FullRepositoryId = "nicolas-gagnon/eks-pipeline-app"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "BuildImage"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  stage {
    name = "Scan"
    action {
      name             = "ScanImage"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["build_output"]
      output_artifacts = ["scan_output"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.scan.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "DeployHelm"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["scan_output"]
      version         = "1"
      configuration = {
        ProjectName = aws_codebuild_project.deploy.name
      }
    }
  }
}
resource "aws_ecr_repository" "app_repo" {
  name = "my-app"
  image_scanning_configuration {
    scan_on_push = true
  }
  image_tag_mutability = "MUTABLE"
}
resource "aws_codebuild_project" "build" {
  name         = "build"
  description  = "Build and push Docker image to ECR"
  service_role = "arn:aws:iam::247084108338:role/terraformpipe-codebuild-execution"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspecs/buildspec_build.yml"
  }
}

resource "aws_codebuild_project" "scan" {
  name         = "scan"
  description  = "Scan image with Trivy"
  service_role = "arn:aws:iam::247084108338:role/terraformpipe-codebuild-execution"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspecs/buildspec_scan.yml"
  }
}

resource "aws_codebuild_project" "deploy" {
  name         = "deploy"
  description  = "Deploy image to EKS with Helm"
  service_role = "arn:aws:iam::247084108338:role/terraformpipe-codebuild-execution"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspecs/buildspec_deploy.yml"
  }
}
