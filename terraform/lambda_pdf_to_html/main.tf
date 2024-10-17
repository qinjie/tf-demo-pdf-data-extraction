data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_lambda_${var.function_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "lambda" {
  name = "lambda-permissions"
  role = aws_iam_role.iam_for_lambda.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetBucketLocation",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "textract:AnalyzeDocument"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

locals {
  lambda_func_zip = "${path.module}/lambda_function.zip"
}

data "archive_file" "lambda_func" {
  type        = "zip"
  source_dir  = var.src_folder
  output_path = local.lambda_func_zip
}

resource "aws_lambda_function" "lambda_func" {
  filename         = local.lambda_func_zip
  function_name    = var.function_name
  handler          = "main.lambda_handler"
  layers           = var.lambda_layers
  role             = aws_iam_role.iam_for_lambda.arn
  runtime          = var.python_version
  source_code_hash = data.archive_file.lambda_func.output_base64sha256
  timeout          = 900
  memory_size      = 3600

  environment {
    variables = {
      foo = "bar"
    }
  }
  tracing_config {
    mode = "Active"
  }

  tags = var.tags
}
