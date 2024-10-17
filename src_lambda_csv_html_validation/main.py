from typing import Dict, List
import boto3
from botocore.config import Config
from botocore.exceptions import ClientError
import json
import pathlib
from urllib.parse import unquote_plus

import sys
import os

# Add current folder to Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from utils import read_s3_file, upload_file_to_s3, create_directories, get_aws_region


# Configuration
S3_SOURCE_FOLDER = 'staging'
S3_TARGET_FOLDER = 'validation'
LOCAL_FOLDER = '/tmp'
BEDROCK_REGION = 'us-east-1'
DEFAULT_MODEL_ID = 'anthropic.claude-3-sonnet-20240229-v1:0'

# Use longer timeout waiting for result (default 60s)
config = Config(read_timeout=1000, region_name = BEDROCK_REGION)
bedrock_client = boto3.client(service_name='bedrock-runtime', config=config)
create_directories(LOCAL_FOLDER)


def get_completion_from_llm(user_message:Dict, system_prompt:str=None, prefill:str=None, modelId:str=None):
    """
    Get a completion from an LLM model.
    """
    if not modelId:
        modelId = DEFAULT_MODEL_ID
        
    inference_config = {
        "temperature": 0.0,
         "maxTokens": 4096
    }

    # Construct params for converse API
    converse_api_params = {
        "modelId": modelId,
        "messages": [user_message],
        "inferenceConfig": inference_config
    }
    if system_prompt:
        converse_api_params["system"] = [{"text": system_prompt}]
    if prefill:
        converse_api_params["messages"].append({"role": "assistant", "content": [{"text": prefill}]})

    # Use bedrock client to call LLM
    try:
        response = bedrock_client.converse(**converse_api_params)
        text_content = response['output']['message']['content'][0]['text']
        return text_content
    except ClientError as err:
        message = err.response['Error']['Message']
        print(f"A client error occured: {message}")


def process_file(bucket:str, html_file_key:str, csv_file_keys:List[str])->str:
    # Prompts for LLM
    system_prompt = """
        You are an experienced financial analyst.  
        """
    user_prompt_template = r"""
        You are tasked to analyze the provided bank statement in HTML or PDF format and the corresponding CSV files. Make sure that the data in the CSVs accurately reflects the information presented in the bank statement. Ignore any format descrepencies. Identify any suspicious numbers, discrepancies, or incorrect extractions from the bank statement and flag them for further review.

        Please provide your response in JSON format, which should include following fields:
        1. Whether the data in CSV is correctly extracted from the bank statement.
        2. List of flagged discrepancies or suspicious values, if there is any. Each item should include:
            1) The original value from the bank statement
            2) The extracted value from the CSV file
            3) A brief explanation of the discrepancy (optional)
        3. Any additional notes or comments about the analysis process.

        Here is a smple of the output JSON.
            {
            "overall_accurate": false,
            "flagged_discrepancies": [
                {
                    "original_value": "1234567890",
                    "extracted_value": "1234567891",
                    "explanation": "Possible typo or error in extraction"
                }
            ],
            "additional_comments": [
                "The analysis process involved manual review of the bank statement and CSV files to ensure data accuracy."
            ]
            }
        
        Only respond with the JSON object. Do not include any other text in your response.
        """
    prefill = 'Assistant:'
    
    html_content = read_s3_file(bucket, html_file_key)
    # print('Input File Content:', html_content)
            
    print(pathlib.Path(html_file_key).name)
    message_content = [
        { "text": user_prompt_template },
                { "document": {
                "format": "html",
                "name": pathlib.Path(html_file_key).stem.strip().replace('  ',' '),
                "source": {
                    "bytes": html_content
                }
            }
        },
    ]
    
    # Process each CSV file    
    for idx, csv_file_key in enumerate(csv_file_keys):
        print(f'CSV {idx}: {pathlib.Path(csv_file_key).name}')
        csv_content = read_s3_file(bucket, csv_file_key)
        message_content.append(
            { "document": {
                    "format": "csv",
                    "name": pathlib.Path(csv_file_key).stem.strip().replace('  ',' '),
                    "source": {
                        "bytes": csv_content
                    }
                }
            }
        )

    user_message = {
        "role": "user",
        "content": message_content,
    }
    # print(user_message)
    
    result = get_completion_from_llm(user_message, system_prompt, prefill)        
    return result


def upload_files_to_s3(local_file_paths:List[str], bucket:str, target_folder_key:str):
    # Upload result files to S3 bucket
    target_folder_path = pathlib.Path(target_folder_key)
    result_keys = []
    for local_file_path in local_file_paths:
        local_file_name = pathlib.Path(local_file_path).name
        s3_object_key = target_folder_path.joinpath(local_file_name).as_posix()
        upload_file_to_s3(local_file_path, bucket, s3_object_key)    
        result_keys.append(s3_object_key)
    
    return result_keys


def get_target_file_key(source_key):
    sub_folder_path = pathlib.Path(source_key).parent.relative_to(S3_SOURCE_FOLDER)
    file_stem = pathlib.Path(source_key).stem
    
    target_key = pathlib.Path(S3_TARGET_FOLDER).joinpath(sub_folder_path).joinpath(file_stem + '.json')
    target_key = target_key.as_posix()
    print(f'source: {source_key}', f'target: {target_key}')
    return target_key


def lambda_handler(event, context):
    # Debug
    print(event)

    # Event coming from previous Lambda in step function
    bucket = event['bucket']
    html_file_key = event['html_file_key']
    pdf_file_key = event['pdf_file_key']
    csv_file_keys = event['csv_file_keys']
       
    validation_result = process_file(bucket, html_file_key, csv_file_keys)
    print('Result:', validation_result,'\n')

    validation_result = json.loads(validation_result)
    output = {
        "bucket": bucket,
        "pdf_file_key": pdf_file_key,
        "html_file_key": html_file_key,
        "csv_file_keys": csv_file_keys,
        "validation_file_key": "",
        "validation_result": validation_result
    }
    
    # Export validation result to file and upload to S3
    if not validation_result:
        print("Validation result is None")
        raise Exception(f"{json.dumps(output)}")        

    # Export data into file
    local_file =  pathlib.Path(LOCAL_FOLDER).joinpath('validation.json').as_posix()
    with open(local_file, 'w') as f:
        f.write(json.dumps(validation_result))

    validation_file_key = get_target_file_key(html_file_key)
    upload_file_to_s3(local_file, bucket, validation_file_key)

    output["validation_file_key"] = validation_file_key,
    print(output)
    
    # Raise exception if validation failed
    if not validation_result.get('overall_accurate'):
        print('Validation failed.')
        raise Exception(f"{json.dumps(output)}")
    
    return output


if __name__ == '__main__':
    # Test
    event = {
        "bucket": "qinjie-460453255610-us-east-1",
        "pdf_file_key": "raw/2024-10-10/Anonymised Citibank.pdf",
        "html_file_key": "staging/2024-10-10/Anonymised Citibank.html",
        "csv_file_keys": [
            "result/2024-10-10/Anonymised Citibank/Holding in Cash Deposits Short Term.csv",
            "result/2024-10-10/Anonymised Citibank/Holdings in Equity.csv",
            "result/2024-10-10/Anonymised Citibank/Holding in Options Swaps Structure Assets.csv",
            "result/2024-10-10/Anonymised Citibank/Transaction Records.csv"
        ]
    }
    lambda_handler(event, None)
