

resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket        = "eks-pipeline-artifacts-nicolas-gagnon"
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
        BranchName       = "DEV"
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
        ProjectName = "build"
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
        ProjectName = "scan"
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
        ProjectName = "deploy"
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
