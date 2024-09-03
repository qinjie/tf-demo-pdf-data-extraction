import boto3
import pathlib
from textractor import Textractor
from textractor.data.constants import TextractFeatures
from textractor.entities.document import Document
from pdf2image import convert_from_path
from typing import List
from urllib.parse import unquote_plus

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from utils import download_file_from_s3, upload_file_to_s3

# Configuration
S3_TARGET_FOLDER = 'staging'
LOCAL_FOLDER = '/tmp'


def export_pdf_pages_to_images(pdf_path:str, output_dir:str)->List[str]:
    """
    Export each page in PDF file into an image.
    Input:
        - pdf_path: Path to the PDF file
        - output_dir: Path to the folder which stores the image files
    Output:
        List of file path to the generated image files
    """
    images = convert_from_path(pdf_path, dpi=300)  # Set dpi for high resolution

    output_files = []
    # Save each page as an image file
    for i, image in enumerate(images):
        image_path = f'{output_dir}/page_{i + 1}.png'  # Save as PNG for high quality
        image.save(image_path, 'PNG')
        output_files.append(image_path)

    return output_files


def extract_page_from_image(input_doc_path:str)->Document:
    """
    Extract the data in a document file.
    Input: 
        - input_doc_path: Path to the document file
    Output: 
        Document object which contains the page
    """
    extractor = Textractor()

    document = extractor.analyze_document(
                   file_source=input_doc_path,
                   features=[TextractFeatures.LAYOUT, TextractFeatures.TABLES, TextractFeatures.FORMS],
                   save_image=True)

    return document


def process_file(bucket, pdf_key, html_key):
    """
    Main function
    """
    pdf_file = pathlib.Path(pdf_key).name
    html_file = pathlib.Path(pdf_key).stem + '.html'
    print(f'{pdf_file} -> {html_file}')
    
    local_folder = LOCAL_FOLDER
    local_file =  pathlib.Path(local_folder).joinpath(pdf_file).as_posix()
    result_file = pathlib.Path(local_folder).joinpath(html_file).as_posix()
    
    download_file_from_s3(bucket, pdf_key, local_file)

    output_files = export_pdf_pages_to_images(pdf_path=local_file, output_dir=local_folder)
    print(output_files)
    
    document = Document()

    for input_document in output_files:
        print(f"Extracting {input_document}...")
        doc = extract_page_from_image(input_document)
        document.pages.extend(doc.pages)
    
    print('Total pages:', len(document.pages))

    html = document.to_html()
    with open(result_file, 'w') as f:
        f.write(html)
    
    upload_file_to_s3(result_file, bucket, html_key)


def lambda_handler(event, context):
    # Debug
    print(event)

    # Get the S3 bucket and object key from the event
    bucket = event['Records'][0]['s3']['bucket']['name']
    source_key = event['Records'][0]['s3']['object']['key']
    # Fix the problem where Lambda may replace space with +
    source_key = unquote_plus(source_key)
    
    s3_folder = S3_TARGET_FOLDER
    html_file = pathlib.Path(source_key).stem + '.html'
    target_key = pathlib.Path(s3_folder).joinpath(html_file).as_posix()
    print(f'source: {source_key}')
    print(f'target: {target_key}')
    
    process_file(bucket, source_key, target_key)
    

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
                        "key": "raw/JPM Anonymised.pdf",
                    }
                }
            }
        ]
    }
    lambda_handler(event, None)
