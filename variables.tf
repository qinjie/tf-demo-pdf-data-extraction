variable "project" {
  description = "Project name"
  type        = string
  default     = "test"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "python_version" {
  type        = string
  default     = "python3.11"
  description = "Python version"
}

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
  default     = {}
}
