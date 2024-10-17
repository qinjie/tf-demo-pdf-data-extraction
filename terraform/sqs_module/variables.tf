variable "name_prefix" {
  description = "Prefix for the queue names"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket to receive notifications from"
  type        = string
}

variable "dlq_message_retention_seconds" {
  description = "Number of seconds to retain messages in the dead-letter queue"
  type        = number
  default     = 1209600 # 14 days
}

variable "max_receive_count" {
  description = "Maximum number of times a message can be received before being sent to the DLQ"
  type        = number
  default     = 5
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout for the main queue"
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "Number of seconds to retain messages in the main queue"
  type        = number
  default     = 345600 # 4 days
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "filter_s3_prefix" {
  type        = string
  description = "The prefix filter for S3 objects that should trigger the SQS notification"
  default     = "raw/"
}

variable "filter_s3_suffix" {
  type        = string
  description = "The suffix filter for S3 objects that should trigger the SQS notification"
  default     = ".pdf"
}