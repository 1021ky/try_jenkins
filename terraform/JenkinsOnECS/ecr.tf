resource "aws_ecr_repository" "try-jenkins-on-ecs-dev-ecr-repo" {
  name                 = "${var.name_prefix}-ecr-repo"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
}
