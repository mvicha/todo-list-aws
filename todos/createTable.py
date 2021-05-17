import json
import os

# from todos import decimalencoder
import decimalencoder
from todoTableClass import handler as todoTableClass

dynamodb = None
create = True


def createTable(event, context):
    tdCreateTable = todoTableClass(table=os.environ['DYNAMODB_TABLE'],
                                   dynamodb=dynamodb, create=create)
    item = tdCreateTable.create_todo_table()

    # create a response
    response = {
        "statusCode": 200,
        "body": json.dumps(item, cls=decimalencoder.DecimalEncoder)
    }

    return response
