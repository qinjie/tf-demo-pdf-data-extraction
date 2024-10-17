output "step_function_arn" {
  description = "ARN of the created Step Function"
  value       = aws_sfn_state_machine.sfn_state_machine.arn
}

output "sns_topic_arn" {
  description = "ARN of the created SNS topic"
  value       = aws_sns_topic.error_topic.arn
}

output "step_function_role_arn" {
  description = "ARN of the IAM role for the Step Function"
  value       = aws_iam_role.step_function_role.arn
}
