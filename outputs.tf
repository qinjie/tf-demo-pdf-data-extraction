output "lambda_arn_pdf_to_html" {
  description = "ARN of the lambda function pdf_to_html"
  value       = module.lambda_function_pdf_to_html.arn
}

output "lambda_arn_html_to_csv" {
  description = "ARN of the lambda function html_to_csv"
  value       = module.lambda_function_html_to_csv.arn
}
