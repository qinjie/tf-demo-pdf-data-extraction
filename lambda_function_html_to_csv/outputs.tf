output "arn" {
  description = "ARN of the lambda function"
  value       = aws_lambda_function.lambda_func.arn
}
