import os
import json
import boto3


def responseMaker(message, statusCode):
    response = {
                "statusCode": statusCode,
                "headers": {'Access-Control-Allow-Headers': 'Content-Type',
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'},
                "body": json.dumps({
                    "message": message
                })
            }
    return(response)


def lambda_handler(event, context):
    path = (event['requestContext']['resourcePath'])
    print(event)