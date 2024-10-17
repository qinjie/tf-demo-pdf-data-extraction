# SNS Error Topic
resource "aws_sns_topic" "error_topic" {
  name              = "${var.environment}_sns_topic"
  tags              = var.tags
  kms_master_key_id = "alias/aws/sns"
  delivery_policy = jsonencode({
    "http" : {
      "defaultHealthyRetryPolicy" : {
        "minDelayTarget" : 20,
        "maxDelayTarget" : 20,
        "numRetries" : 3,
        "numMaxDelayRetries" : 0,
        "numNoDelayRetries" : 0,
        "numMinDelayRetries" : 0,
        "backoffFunction" : "linear"
      },
      "disableSubscriptionOverrides" : false
    }
  })
}

data "aws_iam_policy_document" "sns_error_topic_policy" {
  statement {
    effect    = "Allow"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.error_topic.arn]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_sfn_state_machine.sfn_state_machine.arn]
    }
  }
}

resource "aws_sns_topic_policy" "error_topic" {
  arn    = aws_sns_topic.error_topic.arn
  policy = data.aws_iam_policy_document.sns_error_topic_policy.json
}

# SNS Success Topic
resource "aws_sns_topic" "success_topic" {
  name              = "${var.environment}_sns_topic"
  tags              = var.tags
  kms_master_key_id = "alias/aws/sns"
  delivery_policy = jsonencode({
    "http" : {
      "defaultHealthyRetryPolicy" : {
        "minDelayTarget" : 20,
        "maxDelayTarget" : 20,
        "numRetries" : 3,
        "numMaxDelayRetries" : 0,
        "numNoDelayRetries" : 0,
        "numMinDelayRetries" : 0,
        "backoffFunction" : "linear"
      },
      "disableSubscriptionOverrides" : false
    }
  })
}

data "aws_iam_policy_document" "sns_success_topic_policy_document" {
  statement {
    effect    = "Allow"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.success_topic.arn]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_sfn_state_machine.sfn_state_machine.arn]
    }
  }
}

resource "aws_sns_topic_policy" "success_topic" {
  arn    = aws_sns_topic.success_topic.arn
  policy = data.aws_iam_policy_document.sns_success_topic_policy_document.json
}

# Step Function
resource "aws_cloudwatch_log_group" "sfn_log_group" {
  name              = "/aws/vendedlogs/states/${var.environment}_step_function"
  retention_in_days = 7 # Adjust this value as needed
  tags              = var.tags
}

data "aws_iam_policy_document" "step_function_policy" {
  statement {
    effect    = "Allow"
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
    resources = [var.sqs_queue_arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [var.lambda_pdf_to_html_arn, var.lambda_html_to_csv_arn, var.lambda_csv_html_validation_arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.error_topic.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.sfn_log_group.arn}:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "step_function_role" {
  name = "${var.environment}_step_function_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "step_function_policy" {
  name   = "${var.environment}_step_function_policy"
  role   = aws_iam_role.step_function_role.id
  policy = data.aws_iam_policy_document.step_function_policy.json
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "${var.environment}_step_function"
  role_arn = aws_iam_role.step_function_role.arn
  definition = templatefile("${path.module}/step_function_definition.json", {
    lambda_pdf_to_html_arn         = var.lambda_pdf_to_html_arn,
    lambda_html_to_csv_arn         = var.lambda_html_to_csv_arn,
    lambda_csv_html_validation_arn = var.lambda_csv_html_validation_arn,
    sns_error_topic_arn            = aws_sns_topic.error_topic.arn
    sns_success_topic_arn          = aws_sns_topic.success_topic.arn
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sfn_log_group.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tags       = var.tags
  depends_on = [aws_cloudwatch_log_group.sfn_log_group]
}

resource "aws_cloudwatch_log_resource_policy" "sfn_log_policy" {
  policy_name = "${var.environment}_sfn_log_policy"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.sfn_log_group.arn}:*"
      }
    ]
  })
}
