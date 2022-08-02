variable "resource_tags" {
  description = "Tags to set for all resources"
  type        = map(string)
  default = {
    project     = "project-alpha",
    environment = "dev"
  }
}