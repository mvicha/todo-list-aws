import json


def list(event, context):
    print("Enter here")
    response = {
        "statusCode": 200,
        "body": "Bye bye"
    }
    return response

#import json
#import os

# from todos import decimalencoder
#import decimalencoder
#import boto3
#from todoTableClass import handler as todoTableClass

#dynamodb = None
#print("We are here")
#print(os.environ["DYNAMODB_TABLE"])
#if os.environ['DYNAMODB_TABLE'] != 'TodoDynamoDbTable':
#    dynamodb = boto3.resource('dynamodb')

#def list(event, context):
#    try:
#        tdList = todoTableClass(table=os.environ['DYNAMODB_TABLE'],
#                                dynamodb=dynamodb)
#        item = tdList.scan_todo()
#    except Exception as e:
#        print(f"Exception found: {e}")

    # create a response
#    response = {
#        "statusCode": 200,
#        "body": json.dumps(item, cls=decimalencoder.DecimalEncoder)
#    }

#    return response
