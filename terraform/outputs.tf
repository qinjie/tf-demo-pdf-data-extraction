output "lambda_arn_pdf_to_html" {
  description = "ARN of the lambda function pdf_to_html"
  value       = module.lambda_pdf_to_html.arn
}

output "lambda_arn_html_to_csv" {
  description = "ARN of the lambda function html_to_csv"
  value       = module.lambda_html_to_csv.arn
}

output "lambda_arn_csv_html_validation" {
  description = "ARN of the lambda function csv_html_validation"
  value       = module.lambda_csv_html_validation.arn
}

# You can access the outputs like this:
output "main_queue_url" {
  value = module.my_sqs_queues.main_queue_url
}
