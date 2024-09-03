from typing import Dict, List
import boto3
from botocore.config import Config
from botocore.exceptions import ClientError
import json
import pathlib
from urllib.parse import unquote_plus

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from utils import read_s3_file, upload_file_to_s3, create_directories


# Configuration
S3_TARGET_FOLDER = 'result'
LOCAL_FOLDER = '/tmp'

# Use longer timeout waiting for result (default 60s)
config = Config(read_timeout=1000, region_name = 'us-east-1')
bedrock_client = boto3.client(service_name='bedrock-runtime', config=config)
create_directories(LOCAL_FOLDER)


def get_completion_from_llm(user_message:Dict, system_prompt:str=None, prefill:str=None, modelId:str=None):
    """
    Get a completion from an LLM model.
    """
    if not modelId:
        modelId = 'anthropic.claude-3-sonnet-20240229-v1:0'
        
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


def process_file(bucket:str, source_file_key:str)->List[str]:
    # Prompts for LLM
    system_prompt = """
        You’re an experienced financial analyst. Extract data from financial reports based on requirements.
        """
    user_prompt_template = f"""
        Extract data from the HTML document. Complete all tasks defined in the <tasks> by filling the tables with extracted data from the document.

        <task>
        TASK_DESCRIPTION
        </task>

        <instructions>
        1. Use numbers from the document only.
        2. Do not make up any number if the respective value is not available.
        3. Format date value in "yyyy/MM/dd" format.
        4. Convert and provide the tables in CSV format.
        5. Do not include any comment, prompt or instruction. It is very important that you only provide the final output without any additional text.
        </instructions>

        Provide the table in CSV format as the final output.
        """
    prefill = 'Assistant:'
    
    # Load tasks from a JSON file
    with open('tasks.json') as f:
        tasks = json.load(f)

    html_content = read_s3_file(bucket, source_file_key)
    # print('Input File Content:')
    # print(html_content)
    
    # Process each task
    result_files = []
    for idx, task in enumerate(tasks):
        print(f'Task {idx}: {task["name"]}')
        user_prompt = user_prompt_template.replace('TASK_DESCRIPTION', task["description"])
        user_message = {
            "role": "user",
            "content": [
                { "text": user_prompt },
                { "document": {
                        "format": "html",
                        "name": "financial report in html",
                        "source": {
                            "bytes": html_content
                        }
                    }
                }
            ],
        }
        result = get_completion_from_llm(user_message, system_prompt, prefill)
        # print(result)
        # print()
        
        # Export data into CSV file
        local_file =  pathlib.Path(LOCAL_FOLDER).joinpath(task['output_file']).as_posix()
        with open(local_file, 'w') as f:
            f.write(result)
        
        result_files.append(local_file)
    
    return result_files


def upload_files_to_s3(local_file_paths:List[str], bucket:str, target_folder_key:str):
    # Upload result files to S3 bucket
    target_folder_path = pathlib.Path(target_folder_key)
    for local_file_path in local_file_paths:
        local_file_name = pathlib.Path(local_file_path).name
        s3_object_key = target_folder_path.joinpath(local_file_name).as_posix()
        upload_file_to_s3(local_file_path, bucket, s3_object_key)    
    

def lambda_handler(event, context):
    # Debug
    print(event)
    
    # Get the S3 bucket and object key from the event
    bucket = event['Records'][0]['s3']['bucket']['name']
    source_file_key = event['Records'][0]['s3']['object']['key']
    # Fix the problem where Lambda may replace space with +
    source_file_key = unquote_plus(source_file_key)
    
    # Result files will be placed at S3_TARGET_FOLDER/soure_file_stem/ folder
    source_file_stem = pathlib.Path(source_file_key).stem
    target_folder_key = pathlib.Path(S3_TARGET_FOLDER).joinpath(source_file_stem).as_posix()
    
    local_file_paths = process_file(bucket, source_file_key)
    upload_files_to_s3(local_file_paths, bucket, target_folder_key)


if __name__ == '__main__':
    # Test
    event = {
        "Records": [
            {
                "s3": {
                    "bucket": {
                        "name": "textract-460453255610",
                    },
                    "object": {
                        "key": "staging/JPM Anonymised.html",
                    }
                }
            }
        ]
    }
    lambda_handler(event, None)
