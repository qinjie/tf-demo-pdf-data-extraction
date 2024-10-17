import boto3
import pathlib
from botocore.exceptions import NoCredentialsError, ClientError

import re

s3_client = boto3.client('s3')


def sanitize_filename(filename:str, replacement:str='_')->str:
    # Define a pattern for invalid characters in file names
    invalid_chars = r'[<>:"/\\|?*]'
    
    # Use regex to replace invalid characters with the specified replacement character
    sanitized = re.sub(invalid_chars, replacement, filename)
    
    # Optionally, strip leading and trailing whitespace or replacement characters
    sanitized = sanitized.strip().strip(replacement)
    
    # Ensure the filename is not empty after sanitization
    if not sanitized:
        raise ValueError("The sanitized filename is empty.")
    
    return sanitized
  

def create_parent_directories(file_path:str):
    """
    Make sure containing folders exists.
    """
    pathlib.Path(file_path).parents[0].mkdir(parents=True, exist_ok=True)
        

def download_file_from_s3(bucket_name:str, object_key:str, local_file_path:str)->bool:
    """
    Download a file from S3 bucket.
    Input:
        - bucket_name: S3 bucket name
        - object_key: Key to the object to be downloaded
        - local_path_path: Path to the downloaded file including file name
    Output:
        - Return True if download is successful, else return False
    """
    # Create an S3 client
    s3 = boto3.client('s3')

    try:
        # Download the file from S3
        s3.download_file(bucket_name, object_key, local_file_path)
        print(f"File downloaded successfully to {local_file_path}")
        return True
    except Exception as e:
        print(f"Error downloading file: {e}")
        return False
      

def upload_file_to_s3(local_file_path:str, bucket_name:str, s3_object_key:str)->bool:
    """
    Upload a local file to a S3 bucket.
    """
    try:
        # Upload the file
        s3_client.upload_file(local_file_path, bucket_name, s3_object_key)
        print(f"File {local_file_path} uploaded to {bucket_name}/{s3_object_key} successfully.")
    except FileNotFoundError:
        print(f"The file {local_file_path} was not found.")
        raise
    except NoCredentialsError:
        print("Credentials not available.")
        raise
    except ClientError as e:
        print(f"An error occurred: {e}")
        raise
  

def read_s3_file(bucket_name, object_key):
    """
    Read an S3 file and return its content
    """
    try:
        # Retrieve the object from the S3 bucket
        response = s3_client.get_object(Bucket=bucket_name, Key=object_key)

        # Read the content of the file
        file_content = response['Body'].read().decode('utf-8')

        return file_content

    except s3_client.exceptions.NoSuchBucket:
        print(f"The bucket {bucket_name} does not exist.")
    except s3_client.exceptions.NoSuchKey:
        print(f"The object {object_key} does not exist in the bucket {bucket_name}.")
    except Exception as e:
        print(f"An error occurred: {e}")
