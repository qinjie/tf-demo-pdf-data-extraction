variable "environment" {
  type        = string
  description = "The environment (e.g., dev, prod)"
}

variable "sqs_queue_arn" {
  type        = string
  description = "The ARN of the SQS queue"
}

variable "step_function_arn" {
  type        = string
  description = "The ARN of the Step Function"
}

variable "batch_size" {
  type        = number
  description = "The batch size for SQS queue parameters"
  default     = 1
}

variable "invocation_type" {
  type        = string
  description = "The invocation type for Step Function state machine parameters"
  default     = "FIRE_AND_FORGET"
}

variable "tags" {
  type        = map(string)
  description = "Tags to be applied to the resources"
  default     = {}
}