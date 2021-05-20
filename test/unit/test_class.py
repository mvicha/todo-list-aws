import json
import urllib3


class remoteTableClass():
    def launchEvent(self, endpoint_url, action, params=None):
        http = urllib3.PoolManager()

        if action in ['create', 'update']:
            if action == 'create':
                method = 'POST'
            else:
                method = 'PUT'

        elif action != 'delete':
            method = 'GET'

        else:
            method = 'DELETE'

        try:
            r = http.request(
                method,
                endpoint_url,
                body=params
            )

            if action in ["create", "update", "get", "list", "translate"]:
                response = json.loads(r.data.decode('utf-8'))
                try:
                    if 'message' in response:
                        httpCode = 500
                        responseBody = {
                            'Items': json.dumps({
                                'errorCode': 0x01,
                                'errorMsg': response['message']
                            })
                        }
                    else:
                        httpCode = 200
                        responseBody = {
                            'Items': json.dumps({
                                'errorCode': 200,
                                'errorMsg': response
                            })
                        }
                except Exception as e:
                    httpCode = 501
                    responseBody = {
                        'Items': json.dumps({
                            'errorCode': 0x02,
                            'errorMsg': e
                        })
                    }
            else:
                httpCode = 200
                responseBody = {
                    'Items': json.dumps({
                        'errorCode': 0x00,
                        'errorMsg': 'Todo deleted successfully'
                    })
                }
        except Exception as e:
            httpCode = 500
            responseBody = {
                'Items': json.dumps({
                    'errorCode': 0x03,
                    'errorMsg': f'Something happened: {e}'
                })
            }
        response = {
            "statusCode": httpCode,
            "body": json.dumps(responseBody)
        }
        return response
        