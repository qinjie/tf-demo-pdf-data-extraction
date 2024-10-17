# Extract CSV from HTML using Bedrock

This project demonstrates how to extract tabular data from a HTML file using LLM in Bedrock.

- Multiple tasks can be defined in `tasks.json` file.
- Result files will be uploaded into S3 bucket folder which is the same name as the HTML file.

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

3. Check the result in s3 bucket.
