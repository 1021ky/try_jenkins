variable "name_prefix" {
  type    = string
  default = "try-jenkins-on-ecs-dev"
}
variable "env" {
  type    = string
  default = "dev"
}
variable "service_name" {
  type    = string
  default = "try-jenkins"
}
variable "resource_tags" {
  type = map(string)
  default = {
    Name        = "try-jenkins-on-ecs"
    Env         = "dev"
    ServiceName = "try-jenkins"
  }
}
