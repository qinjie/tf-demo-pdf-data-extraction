resource "aws_sqs_queue" "deadletter_queue" {
  name = "${var.name_prefix}-deadletter-queue"

  message_retention_seconds = var.dlq_message_retention_seconds
  tags                      = var.tags
}

resource "aws_sqs_queue" "main_queue" {
  name = "${var.name_prefix}-main-queue"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.deadletter_queue.arn
    maxReceiveCount     = var.max_receive_count
  })

  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  tags                       = var.tags
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.s3_bucket_name

  queue {
    queue_arn = aws_sqs_queue.main_queue.arn
    events    = ["s3:ObjectCreated:*"]
    filter_prefix = var.filter_s3_prefix
    filter_suffix = var.filter_s3_suffix
  }
}

resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.main_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.main_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = "arn:aws:s3:::${var.s3_bucket_name}"
          }
        }
      }
    ]
  })
}
