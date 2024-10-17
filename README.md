# Data Extraction from Bank Statements

Imagine you have a bank statement in PDF showing your multiple asset performance. You want to summarize it into multiple tables, where data in each table may be from different sections in the statement. 

This project demonstrates how to accomblish above task using Large Language Model (LLM). The implementation is done in AWS using its Bedrock, Textract and other supporting services.

* Bedrock: It provides many popular LLM which we can use on-demand.
* Textract: It extract text from image files after PDF file is converted into images.

## Architecture

<img src="/Users/qinjie/Library/Application Support/typora-user-images/image-20241017102916907.png" alt="image-20241017102916907" style="zoom: 50%;" />

### Step Function

<img src="/Users/qinjie/Library/Application Support/typora-user-images/image-20241017103003605.png" alt="image-20241017103003605" style="zoom:50%;" />

### Lambda Functions

1. Lambda_pdf_to_html
   * Convert PDF file to images
   * Call Textract to extract images
   * Combine extracted documents into a HMTL file
2. Lambda_html_to_csv
   * Call LLM to extract CSV files from HTML file
3. Lambda_csv_html_validation
   * Pass HTML and CSV files to LLM for validation
   * Validation result is passed to next step

### S3 Bucket

1. Statements can be placed in any subfolder in `raw/` folder.
2. Result from `lambda_pdf_to_html` function will be placed in `staging` folder.
3. Result from `lambda_html_to_csv` function will be placed in `result` folder.
4. Result from `lambda_csv_html_validation` function will be placed in `validation` folder.

<img src="/Users/qinjie/Library/Application Support/typora-user-images/image-20241017170909212.png" alt="image-20241017170909212"  />



## Setup

### Pre-requisites

For lambda `pdf_to_html`, the `requirements.txt` file cannot be directly used to create the lambda layer. We need to download pre-built zip files to create 2 lambda layers.

1. Create lambda layer for `poppler`.
   - Download file `poppler.zip` from https://github.com/jeylabs/aws-lambda-poppler-layer/releases/download/2.0.0/poppler.zip


2. Create lambda layer for `textract`.

   - https://aws-samples.github.io/amazon-textract-textractor/using_in_lambda.html

   - Download file `textractor-lambda-p311-pdf.zip` from https://github.com/aws-samples/amazon-textract-textractor/actions/runs/9663648259/artifacts/1636289937


### Update Terraform Code

1. After creating the lambda layers, update the lambda layers ARN in the `terraform > lambda_pdf_to_html > main.tf` file.
   * Without setting the lambda layer ARN, you have to manually configure the lambda layers after function creation.
2. Update the `terraform > tfvars > dev.tfvars` file.
   * s3_bucket_name: S3 bucket where statement files will be deposited
   * environment: name of the project, which will be used as name prefix of aws resources

### Terraform Commands

Initialize terraform project. If are using any terraform state backend, update `backend.conf` to configure it accordingly.

```
cd terraform
tf init -backend-config=backend.conf -var-file=tfvars/dev.tfvars
```

Command to deploy and destroy the resources.

```
tf plan -var-file=tfvars/dev.tfvars
```

```
tf apply -var-file=tfvars/dev.tfvars
```

```
tf destroy -var-file=tfvars/dev.tfvars -lock=false
```



### Testing

1. Upload a bankstatement into a subfolder in the `raw/` folder. 

2. Observe the execution of step function. 

3. Check the result in other folders in S3 bucket.
4. You can also subscribe your email to the SNS topic to receive email notification.

![image-20241017171223531](/Users/qinjie/Library/Application Support/typora-user-images/image-20241017171223531.png)

