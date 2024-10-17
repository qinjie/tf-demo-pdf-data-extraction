resource "aws_pipes_pipe" "sqs_to_step_function" {
  name     = "${var.environment}_sqs_to_step_function_pipe"
  role_arn = aws_iam_role.pipes_role.arn
  source   = var.sqs_queue_arn
  target   = var.step_function_arn

  source_parameters {
    sqs_queue_parameters {
      batch_size = var.batch_size
    }
  }

  target_parameters {
    step_function_state_machine_parameters {
      invocation_type = var.invocation_type
    }
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "pipe_logs" {
  name              = "/aws/pipes/${var.environment}_sqs_to_step_function_pipe"
  retention_in_days = 7
}

resource "aws_iam_role" "pipes_role" {
  name = "${var.environment}_eventbridge_pipes_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "pipes.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "pipes_policy" {
  name = "${var.environment}_eventbridge_pipes_policy"
  role = aws_iam_role.pipes_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [var.sqs_queue_arn]
      },
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = [var.step_function_arn]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.pipe_logs.arn}:*"
      }
    ]
  })
}
