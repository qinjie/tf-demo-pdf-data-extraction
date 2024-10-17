variable "function_name" {
  description = "Function name"
  type        = string
  default     = "test"
}

variable "src_folder" {
  description = "Source code folder"
  type        = string
}

variable "python_version" {
  type        = string
  default     = "python3.11"
  description = "Python version"
}

variable "tags" {
  description = "Tags to set on the lambda function."
  type        = map(string)
  default     = {}
}

variable "lambda_layers" {
  description = "Layers for the lambda function"
  type        = list(string)
  default     = []
}
