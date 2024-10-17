variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue"
  type        = string
}

variable "lambda_pdf_to_html_arn" {
  description = "ARN of the PDF to HTML Lambda function"
  type        = string
}

variable "lambda_html_to_csv_arn" {
  description = "ARN of the HTML to CSV Lambda function"
  type        = string
}

variable "lambda_csv_html_validation_arn" {
  description = "ARN of the CSV HTML validation Lambda function"
  type        = string
}
