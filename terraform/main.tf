terraform {
  # backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.11.0"
    }
  }
}

data "aws_region" "current" {}

module "lambda_pdf_to_html" {
  source         = "./lambda_pdf_to_html"
  function_name  = "${var.environment}_pdf_to_html"
  src_folder     = "../src_lambda_pdf_to_html"
  python_version = var.python_version
  lambda_layers = [
  "arn:aws:lambda:${data.aws_region.current.name}:460453255610:layer:textractor-lambda-p311-pdf:1", "arn:aws:lambda:${data.aws_region.current.name}:460453255610:layer:poppler:3"]
  tags = var.tags
}

module "lambda_html_to_csv" {
  source         = "./lambda_html_to_csv"
  function_name  = "${var.environment}_html_to_csv"
  src_folder     = "../src_lambda_html_to_csv"
  python_version = var.python_version
  tags           = var.tags
}

module "lambda_csv_html_validation" {
  source         = "./lambda_csv_html_validation"
  function_name  = "${var.environment}_csv_html_validation"
  src_folder     = "../src_lambda_csv_html_validation"
  python_version = var.python_version
  tags           = var.tags
}

module "my_sqs_queues" {
  source           = "./sqs_module"
  s3_bucket_name   = var.s3_bucket_name
  name_prefix      = var.environment
  tags             = var.tags
  filter_s3_prefix = "raw/"
  filter_s3_suffix = ".pdf"

  # Optionally override defaults
  # dlq_message_retention_seconds = 1209600
  # max_receive_count             = 5
  # visibility_timeout_seconds    = 30
  # message_retention_seconds     = 345600
}

module "step_function" {
  source = "./step_function_module"

  sqs_queue_arn                  = module.my_sqs_queues.main_queue_arn
  lambda_pdf_to_html_arn         = module.lambda_pdf_to_html.arn
  lambda_html_to_csv_arn         = module.lambda_html_to_csv.arn
  lambda_csv_html_validation_arn = module.lambda_csv_html_validation.arn
  environment                    = var.environment
  tags                           = var.tags
}

module "eventbridge_pipe" {
  source = "./eventbridge_pipe_module"

  environment       = var.environment
  sqs_queue_arn     = module.my_sqs_queues.main_queue_arn
  step_function_arn = module.step_function.step_function_arn
  tags              = var.tags
}
