output "pipe_arn" {
  description = "The ARN of the EventBridge Pipe"
  value       = aws_pipes_pipe.sqs_to_step_function.arn
}

output "pipe_id" {
  description = "The ID of the EventBridge Pipe"
  value       = aws_pipes_pipe.sqs_to_step_function.id
}

output "pipe_role_arn" {
  description = "The ARN of the IAM role used by the EventBridge Pipe"
  value       = aws_iam_role.pipes_role.arn
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for the EventBridge Pipe"
  value       = aws_cloudwatch_log_group.pipe_logs.arn
}