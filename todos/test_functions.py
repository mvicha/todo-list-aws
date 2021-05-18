""" This is a function written to test other todo funcitons after deployment """

import json
import logging
import os
import time
import uuid

import boto3

dynamodb = boto3.resource('dynamodb')
client = boto3.client('lambda')

# Get stage and service names
stgName = os.environ.get('serverless_stgname')
svcName = os.environ.get('serverless_svcame')


fcnPrefix = f"{svcName}-{stgName}"

def create(text):
    """ Test function used to invoke create function """
    inputParams = {
        'body': {
            'text': text
        }
    }

    try:
        create_response = client.invoke(
            FunctionName = f'{fcnPrefix}-create',
            InvocationType = 'RequestResponse',
            Payload = json.dumps(inputParams)
        )
    except Exception as e:
        raise Exception(f'Exception occured when testing create function: {e}')

    # Get variable from create function Response body
    response = json.loads(create_response['Payload'].read())['body']

    # Get created id from create function Response
    todoId = json.loads(response)['id']

    return todoId

def lst():
    """ Test function used to invoke list function """
    try:
        list_response = client.invoke(
            FunctionName = f'{fcnPrefix}-list',
            InvocationType = 'RequestResponse',
        )
    except Exception as e:
        raise Exception(f'Exception occured when testing list function: {e}')

    response = json.loads(list_response['Payload'].read())['body']
    
    return response

def get(todoId):
    """ Test function used to invoke get function """
    pathParams = {
        'pathParameters': {
            'id': todoId
        }
    }

    try:
        get_response = client.invoke(
            FunctionName = f'{fcnPrefix}-get',
            InvocationType = 'RequestResponse',
            Payload = json.dumps(pathParams)
        )
    except Exception as e:
        raise Exception(f'Exception occured when testing get function: {e}')

    response = json.loads(get_response['Payload'].read())
    
    return response

def translate(todoId, target_language):
    """ Test function used to invoke translate function """
    pathParams = {
        'pathParameters': {
            'id': todoId,
            'target_language': target_language
        }
    }

    try:
        translate_response = client.invoke(
            FunctionName = f'{fcnPrefix}-translate',
            InvocationType = 'RequestResponse',
            Payload = json.dumps(pathParams)
        )
    except Exception as e:
        raise Exception(f'Exception occured when testing translate function: {e}')

    response = json.loads(translate_response['Payload'].read())
    
    return response

def update(todoId, text, checked):
    """ Test function used to invoke update function """
    inputParams = {
        'pathParameters': {
            'id': todoId
        },
        'body': {
            'text': text,
            'checked': checked
        }
    }

    try:
        update_response = client.invoke(
            FunctionName = f'{fcnPrefix}-update',
            InvocationType = 'RequestResponse',
            Payload = json.dumps(inputParams)
        )
    except Exception as e:
        raise Exception(f'Exception occured when testing update function: {e}')

    response = json.loads(update_response['Payload'].read())
    
    return response

def delete(todoId):
    """ Test function used to invoke delete function """
    pathParams = {
        'pathParameters': {
            'id': todoId
        }
    }

    try:
        delete_response = client.invoke(
            FunctionName = f'{fcnPrefix}-delete',
            InvocationType = 'RequestResponse',
            Payload = json.dumps(pathParams)
        )
    except Exception as e:
        raise Exception(f'Exception occured when testing delete function: {e}')

    response = json.loads(delete_response['Payload'].read())
    
    return response
    
def functions(event, context):
    if not stgName or not svcName:
        outputs = {
            'errorCode': 0x09,
            'errorMsg': 'Stage and/or Service names not configured. Required for the test to work'
        }
        
        # create a response
        response = {
            "statusCode": 500,
            "body": json.dumps(outputs)
        }
        
        return response

    """ test create function """
    todoId = create("Pasando texto a la función")
    assert len(todoId) > 0

    """ test list function """
    listOutput = lst()
    assert len(listOutput) > 0

    """ test get function """
    getOutput = get(todoId)
    assert getOutput['statusCode'] == 200

    """ test translate function - English """
    translateOutputEnglish = translate(todoId, 'en')
    assert json.loads(translateOutputEnglish['body'])['text'] == 'Passing text to the function'

    """ test translate function - Portuguese """
    translateOutputProtuguese = translate(todoId, 'pt')
    assert json.loads(translateOutputProtuguese['body'])['text'] == 'Passando texto para a função'

    """ test update function """
    updateOutput = update(todoId, 'Nuevo texto de la entrada', 'true')
    assert updateOutput['statusCode'] == 200

    """ test delete function """
    deleteOutput = delete(todoId)
    assert deleteOutput['statusCode'] == 200

    """ Create response output """
    outputs = {
        'todoId': todoId,
        'list': listOutput,
        'get': getOutput,
        'translate to english': translateOutputEnglish,
        'translate to portuguese': translateOutputProtuguese,
        'update': updateOutput,
        'delete': deleteOutput
    }
    # create a response
    response = {
        "statusCode": 200,
        "body": json.dumps(outputs)
    }

    return response
