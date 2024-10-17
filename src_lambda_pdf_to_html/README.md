# Convert PDF to HTML using Textract

This project demonstrates how to extract text from PDF file using Textract.

Pages in source PDF file are first converted into images. Textract is used to extract text and layouts from each image file. Extracted data is combined into a HTML file.

## Setup

The `pdf2image` library requires `poppler` to be installed.
You can create a Lambda layer using pre-build package from `https://github.com/jeylabs/aws-lambda-poppler-layer/releases`.

Manually add the layer to the lambda function.

## Test

For local testing, update `LOCAL_FOLDER = '/tmp'` to `LOCAL_FOLDER = './tmp'` in `main.py file`.

1. Create a Python environment and install required libraries.

```
python3 -m virtualenv --python=python3.11 .venv
source .venv/bin/activate
pip install -r requirements.txt
```

2. Run the script.

```
python main.py
```

3. Check the result in s3 folder.
