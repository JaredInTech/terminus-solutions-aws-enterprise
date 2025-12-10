import json
import boto3
import urllib.parse
from datetime import datetime
import logging
import os


logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3 = boto3.client('s3')

def lambda_handler(event, context):
    """
    Process S3 events and add metadata tags to uploaded objects.
    """
    
    # First thing - log that we're starting
    print("Lambda function started - processing S3 event")
    logger.info("Lambda function started - processing S3 event")
    
    # Log the incoming event for debugging
    print(f"Received event: {json.dumps(event)}")
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Check if we have records
    if 'Records' not in event:
        logger.error("No Records found in event")
        return {
            'statusCode': 400,
            'body': 'No Records in event'
        }
    
    # Track processing results
    processed_count = 0
    error_count = 0
    
    try:
        # Process each record in the event
        for record in event['Records']:
            try:
                # Log each record
                logger.info(f"Processing record: {json.dumps(record)}")
                
                # Extract S3 event details
                s3_event = record['s3']
                bucket_name = s3_event['bucket']['name']
                object_key = urllib.parse.unquote_plus(
                    s3_event['object']['key'], 
                    encoding='utf-8'
                )
                object_size = s3_event['object'].get('size', 0)
                event_time = record['eventTime']
                event_name = record['eventName']
                
                # Log object details
                logger.info(f"Processing object: {bucket_name}/{object_key}")
                logger.info(f"Event: {event_name}, Size: {object_size} bytes")
                
                # Skip if object was deleted
                if event_name.startswith('ObjectRemoved'):
                    logger.info(f"Skipping deleted object: {object_key}")
                    continue
                
                # Get object metadata
                try:
                    response = s3.head_object(
                        Bucket=bucket_name,
                        Key=object_key
                    )
                    content_type = response.get('ContentType', 'unknown')
                    logger.info(f"Object content type: {content_type}")
                    
                except Exception as e:
                    logger.error(f"Error getting object metadata: {str(e)}")
                    error_count += 1
                    continue
                
                # Determine file category based on content type
                file_category = categorize_file(content_type)
                
                # Calculate processing metadata
                processing_metadata = {
                    'ProcessedBy': 'TerminusS3EventProcessor',
                    'ProcessedAt': datetime.utcnow().isoformat(),
                    'FileCategory': file_category,
                    'FileSizeCategory': categorize_size(object_size),
                    'ProcessingVersion': '1.0',
                    'EventType': event_name,
                    'ContentType': content_type
                }
                
                # Add custom tags to the object
                tags = []
                for key, value in processing_metadata.items():
                    tags.append({
                        'Key': key,
                        'Value': str(value)
                    })
                
                logger.info(f"Applying tags: {tags}")
                
                # Apply tags to the S3 object
                try:
                    s3.put_object_tagging(
                        Bucket=bucket_name,
                        Key=object_key,
                        Tagging={'TagSet': tags}
                    )
                    logger.info(f"Successfully tagged object: {object_key}")
                    processed_count += 1
                    
                except Exception as e:
                    logger.error(f"Error tagging object {object_key}: {str(e)}")
                    error_count += 1
                
            except Exception as e:
                logger.error(f"Error processing record: {str(e)}")
                error_count += 1
                continue
        
        # Prepare response summary
        result = {
            'statusCode': 200,
            'processedCount': processed_count,
            'errorCount': error_count,
            'message': f"Processed {processed_count} objects successfully"
        }
        
        # Log summary
        logger.info(f"Processing complete: {json.dumps(result)}")
        
        return result
        
    except Exception as e:
        logger.error(f"Fatal error in Lambda function: {str(e)}")
        raise e

def categorize_file(content_type):
    """Categorize file based on content type."""
    if content_type.startswith('image/'):
        return 'image'
    elif content_type in ['application/pdf', 'application/msword', 
                          'application/vnd.openxmlformats-officedocument']:
        return 'document'
    elif content_type in ['text/csv', 'application/json', 'text/plain']:
        return 'data'
    elif content_type.startswith('video/'):
        return 'video'
    elif content_type.startswith('audio/'):
        return 'audio'
    else:
        return 'other'

def categorize_size(size_bytes):
    """Categorize file size into human-readable categories."""
    if size_bytes < 1024 * 1024:  # < 1MB
        return 'small'
    elif size_bytes < 10 * 1024 * 1024:  # < 10MB
        return 'medium'
    elif size_bytes < 100 * 1024 * 1024:  # < 100MB
        return 'large'
    else:
        return 'extra-large'