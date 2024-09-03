terraform {
  # backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.11.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "lambda_function_pdf_to_html" {
  source         = "./lambda_function_pdf_to_html"
  function_name  = "${var.environment}_pdf_to_html"
  src_folder     = "./src_lambda_pdf_to_html"
  python_version = var.python_version
  lambda_layers  = ["arn:aws:lambda:us-east-1:460453255610:layer:textractor-lambda-p311-pdf:1", "arn:aws:lambda:us-east-1:460453255610:layer:poppler:3"]
  tags           = var.tags
}

module "lambda_function_html_to_csv" {
  source         = "./lambda_function_html_to_csv"
  function_name  = "${var.environment}_html_to_csv"
  src_folder     = "./src_lambda_html_to_csv"
  python_version = var.python_version
  tags           = var.tags
}
